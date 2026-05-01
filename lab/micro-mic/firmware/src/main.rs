#![no_std]
#![no_main]

mod analog;
mod audio;
mod clock_capture;
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
            Alternate, Analog, Input, Output, PushPull,
            gpioa::{PA0, PA3},
            gpiob::PB0,
            gpioc::{PC3, PC13},
        },
        hal::adc::{Channel, OneShot},
        pac::{ADC2, TIM1},
        prelude::*,
        pwm::{C1, ComplementaryDisabled, Pwm},
        rcc::rec::AdcClkSel,
    };

    use crate::{
        analog::AdcDelay,
        audio::{self, AudioSampler},
        clock_capture::ClockCapture,
        config, net,
        net::Net,
        telemetry, timebase,
    };

    fn read_adc_pin<ADC, PIN>(adc: &mut adc::Adc<ADC, adc::Enabled>, pin: &mut PIN) -> u16
    where
        PIN: Channel<ADC>,
        adc::Adc<ADC, adc::Enabled>: OneShot<ADC, u32, PIN>,
    {
        match adc.read(pin) {
            Ok(value) => value.min(u16::MAX as u32) as u16,
            Err(_) => 0,
        }
    }

    fn process_audio(
        audio: &mut AudioSampler,
        net: &mut Net<'static>,
        packet: &mut [u8; telemetry::AUDIO_PACKET_LEN],
        sequence: &mut u32,
        sample_index: &mut u64,
        latest_pc0: &mut u16,
    ) {
        let now_ms = timebase::now_ms();
        let sample_rate_hz = audio.sample_rate_hz();
        let frame_sequence = *sequence;
        let frame_start = *sample_index;

        if audio.process_ready_frame(|samples, flags| {
            *latest_pc0 = samples[config::AUDIO_FRAME_SAMPLES - 1];
            telemetry::encode_audio(
                packet,
                frame_sequence,
                now_ms,
                frame_start,
                sample_rate_hz,
                audio::CHANNEL_ID_PC0,
                flags,
                samples,
            );
            let _ = net.send(now_ms, packet);
        }) {
            *sequence = (*sequence).wrapping_add(1);
            *sample_index = (*sample_index).wrapping_add(config::AUDIO_FRAME_SAMPLES as u64);
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
        clock_capture: ClockCapture,
        _clock_capture_pin: PA0<Alternate<1>>,
        audio: AudioSampler,
        audio_packet: [u8; telemetry::AUDIO_PACKET_LEN],
        audio_sequence: u32,
        audio_sample_index: u64,
        latest_pc0: u16,
        adc_status: adc::Adc<ADC2, adc::Enabled>,
        adc_pa3: PA3<Analog>,
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
            .pll2_p_ck(40.MHz())
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
            config::CLOCK_HZ.Hz(),
            ccdr.peripheral.TIM1,
            &ccdr.clocks,
        );
        let clock_max_duty = clock_pwm.get_max_duty();
        clock_pwm.set_duty(clock_max_duty / 2);
        clock_pwm.enable();

        let clock_capture_pin = gpioa.pa0.into_alternate::<1>();
        let clock_capture = ClockCapture::new(
            cx.device.TIM2,
            ccdr.peripheral.TIM2,
            ccdr.clocks.timx_ker_ck().raw(),
        );

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
        let (adc1, adc2) = adc::adc12(
            cx.device.ADC1,
            cx.device.ADC2,
            40.MHz(),
            &mut adc_delay,
            ccdr.peripheral.ADC12,
            &ccdr.clocks,
        );
        let mut adc1 = adc1.enable();
        adc1.set_resolution(adc::Resolution::SixteenBit);
        adc1.set_sample_time(adc::AdcSampleTime::T_64);

        let mut adc_status = adc2.enable();
        adc_status.set_resolution(adc::Resolution::SixteenBit);
        adc_status.set_sample_time(adc::AdcSampleTime::T_64);

        let adc_pa3 = gpioa.pa3.into_analog();
        let adc_pc0 = gpioc.pc0.into_analog();
        let adc_pc3 = gpioc.pc3.into_analog();
        let digital_pc13 = gpioc.pc13.into_floating_input();

        let audio = AudioSampler::new(
            adc1,
            adc_pc0,
            cx.device.DMA1,
            ccdr.peripheral.DMA1,
            cx.device.TIM6,
            ccdr.peripheral.TIM6,
            &ccdr.clocks,
        );

        timebase::init(cx.core.SYST, ccdr.clocks);

        (
            Shared {},
            Local {
                net,
                phy,
                status_led,
                _clock_pwm: clock_pwm,
                clock_capture,
                _clock_capture_pin: clock_capture_pin,
                audio,
                audio_packet: [0; telemetry::AUDIO_PACKET_LEN],
                audio_sequence: 0,
                audio_sample_index: 0,
                latest_pc0: 0,
                adc_status,
                adc_pa3,
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
            clock_capture,
            audio,
            audio_packet,
            audio_sequence,
            audio_sample_index,
            latest_pc0,
            adc_status,
            adc_pa3,
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
            process_audio(
                cx.local.audio,
                cx.local.net,
                cx.local.audio_packet,
                cx.local.audio_sequence,
                cx.local.audio_sample_index,
                cx.local.latest_pc0,
            );

            if now_ms.wrapping_sub(*cx.local.last_sample_ms) >= config::SAMPLE_PERIOD_MS {
                *cx.local.last_sample_ms = now_ms;

                let adc0 = read_adc_pin(cx.local.adc_status, cx.local.adc_pa3);
                let adc1 = *cx.local.latest_pc0;
                let adc2 = read_adc_pin(cx.local.adc_status, cx.local.adc_pc3);
                let clock = cx.local.clock_capture.sample();

                let packet = telemetry::encode(
                    *cx.local.sequence,
                    now_ms,
                    [adc0, adc1, adc2],
                    cx.local.digital_pc13.is_high(),
                    link_up,
                    clock,
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
