#![no_std]
#![no_main]

mod analog;
mod config;
mod net;
mod telemetry;
mod timebase;

use panic_halt as _;

#[rtic::app(device = stm32h7xx_hal::pac, peripherals = true)]
mod app {
    use smoltcp::time::Instant;
    use stm32h7xx_hal::{
        adc, ethernet,
        ethernet::PHY,
        gpio::{
            Analog, Input, Output, PushPull,
            gpioa::PA3,
            gpiob::PB0,
            gpioc::{PC0, PC3, PC13},
        },
        hal::adc::{Channel, OneShot},
        pac::{ADC1, TIM1},
        prelude::*,
        pwm::{C1, ComplementaryDisabled, Pwm},
        rcc::rec::AdcClkSel,
    };

    use crate::{analog::AdcDelay, config, net, net::Net, telemetry, timebase};

    fn read_adc_pin<PIN>(adc: &mut adc::Adc<ADC1, adc::Enabled>, pin: &mut PIN) -> u16
    where
        PIN: Channel<ADC1>,
        adc::Adc<ADC1, adc::Enabled>: OneShot<ADC1, u32, PIN>,
    {
        match adc.read(pin) {
            Ok(value) => value.min(u16::MAX as u32) as u16,
            Err(_) => 0,
        }
    }

    #[shared]
    struct Shared {}

    #[local]
    struct Local {
        net: Net<'static>,
        phy: ethernet::phy::LAN8742A<ethernet::EthernetMAC>,
        status_led: PB0<Output<PushPull>>,
        _clock_pwm: Pwm<TIM1, { C1 }, ComplementaryDisabled>,
        adc: adc::Adc<ADC1, adc::Enabled>,
        adc_pa3: PA3<Analog>,
        adc_pc0: PC0<Analog>,
        adc_pc3: PC3<Analog>,
        digital_pc13: PC13<Input>,
        sequence: u32,
        last_sample_ms: u32,
    }

    #[init]
    fn init(mut cx: init::Context) -> (Shared, Local) {
        let pwr = cx.device.PWR.constrain();
        let pwrcfg = pwr.smps().freeze();

        // Ethernet DMA buffers live in SRAM3 on this dual-core H7.
        cx.device.RCC.ahb2enr.modify(|_, w| w.sram3en().set_bit());

        let rcc = cx.device.RCC.constrain();
        let mut ccdr = rcc
            .sys_ck(198.MHz())
            .hclk(198.MHz())
            .pll2_p_ck(4.MHz())
            .freeze(pwrcfg, &cx.device.SYSCFG);
        ccdr.peripheral.kernel_adc_clk_mux(AdcClkSel::Pll2P);

        cx.core.SCB.invalidate_icache();
        cx.core.SCB.enable_icache();
        cx.core.DWT.enable_cycle_counter();

        let gpioa = cx.device.GPIOA.split(ccdr.peripheral.GPIOA);
        let gpiob = cx.device.GPIOB.split(ccdr.peripheral.GPIOB);
        let gpioc = cx.device.GPIOC.split(ccdr.peripheral.GPIOC);
        let gpiog = cx.device.GPIOG.split(ccdr.peripheral.GPIOG);

        let mut status_led = gpiob.pb0.into_push_pull_output();
        status_led.set_high();

        let mut clock_pwm = cx.device.TIM1.pwm(
            gpioa.pa8.into_alternate(),
            2.Hz(),
            ccdr.peripheral.TIM1,
            &ccdr.clocks,
        );
        let clock_max_duty = clock_pwm.get_max_duty();
        clock_pwm.set_duty(clock_max_duty / 2);
        clock_pwm.enable();

        let rmii_ref_clk = gpioa.pa1.into_alternate();
        let rmii_mdio = gpioa.pa2.into_alternate();
        let rmii_mdc = gpioc.pc1.into_alternate();
        let rmii_crs_dv = gpioa.pa7.into_alternate();
        let rmii_rxd0 = gpioc.pc4.into_alternate();
        let rmii_rxd1 = gpioc.pc5.into_alternate();
        let rmii_tx_en = gpiog.pg11.into_alternate();
        let rmii_txd0 = gpiog.pg13.into_alternate();
        let rmii_txd1 = gpiob.pb13.into_alternate();

        let mac_addr = smoltcp::wire::EthernetAddress::from_bytes(&config::MAC_ADDRESS);
        let (eth_dma, eth_mac) = ethernet::new(
            cx.device.ETHERNET_MAC,
            cx.device.ETHERNET_MTL,
            cx.device.ETHERNET_DMA,
            (
                rmii_ref_clk,
                rmii_mdio,
                rmii_mdc,
                rmii_crs_dv,
                rmii_rxd0,
                rmii_rxd1,
                rmii_tx_en,
                rmii_txd0,
                rmii_txd1,
            ),
            net::ring(),
            mac_addr,
            ccdr.peripheral.ETH1MAC,
            &ccdr.clocks,
        );

        let mut phy = ethernet::phy::LAN8742A::new(eth_mac.set_phy_addr(0));
        phy.phy_reset();
        phy.phy_init();
        unsafe { ethernet::enable_interrupt() };

        let net = Net::new(net::init_storage(), eth_dma, mac_addr.into(), Instant::ZERO);

        let mut adc_delay = AdcDelay::new(ccdr.clocks.c_ck().to_MHz());
        let mut adc = adc::Adc::adc1(
            cx.device.ADC1,
            4.MHz(),
            &mut adc_delay,
            ccdr.peripheral.ADC12,
            &ccdr.clocks,
        )
        .enable();
        adc.set_resolution(adc::Resolution::SixteenBit);

        let adc_pa3 = gpioa.pa3.into_analog();
        let adc_pc0 = gpioc.pc0.into_analog();
        let adc_pc3 = gpioc.pc3.into_analog();
        let digital_pc13 = gpioc.pc13.into_floating_input();

        timebase::init(cx.core.SYST, ccdr.clocks);

        (
            Shared {},
            Local {
                net,
                phy,
                status_led,
                _clock_pwm: clock_pwm,
                adc,
                adc_pa3,
                adc_pc0,
                adc_pc3,
                digital_pc13,
                sequence: 0,
                last_sample_ms: 0,
            },
        )
    }

    #[idle(
        local = [
            net,
            phy,
            status_led,
            adc,
            adc_pa3,
            adc_pc0,
            adc_pc3,
            digital_pc13,
            sequence,
            last_sample_ms
        ]
    )]
    fn idle(cx: idle::Context) -> ! {
        loop {
            let now_ms = timebase::now_ms();
            let link_up = cx.local.phy.poll_link();

            if link_up || (now_ms / 250) & 1 == 0 {
                cx.local.status_led.set_low();
            } else {
                cx.local.status_led.set_high();
            }

            cx.local.net.poll(now_ms);

            if now_ms.wrapping_sub(*cx.local.last_sample_ms) >= config::SAMPLE_PERIOD_MS {
                *cx.local.last_sample_ms = now_ms;

                let adc0 = read_adc_pin(cx.local.adc, cx.local.adc_pa3);
                let adc1 = read_adc_pin(cx.local.adc, cx.local.adc_pc0);
                let adc2 = read_adc_pin(cx.local.adc, cx.local.adc_pc3);

                let packet = telemetry::encode(
                    *cx.local.sequence,
                    now_ms,
                    [adc0, adc1, adc2],
                    cx.local.digital_pc13.is_high(),
                    link_up,
                );
                let _ = cx.local.net.send(now_ms, &packet);
                *cx.local.sequence = cx.local.sequence.wrapping_add(1);
            }
        }
    }

    #[task(binds = ETH, priority = 3)]
    fn ethernet_event(_: ethernet_event::Context) {
        unsafe { ethernet::interrupt_handler() };
    }

    #[task(binds = SysTick, priority = 15)]
    fn systick_tick(_: systick_tick::Context) {
        timebase::tick();
    }
}
