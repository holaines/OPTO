use core::mem::MaybeUninit;
use core::ptr::addr_of_mut;

use smoltcp::iface::{Config, Interface, SocketHandle, SocketSet, SocketStorage};
use smoltcp::socket::udp;
use smoltcp::time::Instant;
use smoltcp::wire::{HardwareAddress, IpAddress, IpCidr, IpEndpoint};
use stm32h7xx_hal::ethernet;

use crate::config;

#[unsafe(link_section = ".sram3.eth")]
static mut DES_RING: ethernet::DesRing<4, 4> = ethernet::DesRing::new();

static mut STORE: MaybeUninit<Storage<'static>> = MaybeUninit::uninit();

pub struct Storage<'a> {
    socket_storage: [SocketStorage<'a>; 4],
    udp_rx_meta: [udp::PacketMetadata; 4],
    udp_tx_meta: [udp::PacketMetadata; 4],
    udp_rx_data: [u8; 256],
    udp_tx_data: [u8; 512],
}

pub enum SendResult {
    Queued,
    Busy,
    BindFailed,
    SendFailed,
}

pub struct Net<'a> {
    iface: Interface,
    ethdev: ethernet::EthernetDMA<4, 4>,
    sockets: SocketSet<'a>,
    udp_handle: SocketHandle,
}

impl<'a> Net<'a> {
    pub fn new(
        store: &'a mut Storage<'a>,
        mut ethdev: ethernet::EthernetDMA<4, 4>,
        ethernet_addr: HardwareAddress,
        now: Instant,
    ) -> Self {
        let config = Config::new(ethernet_addr);
        let mut iface = Interface::new(config, &mut ethdev, now);
        iface.update_ip_addrs(|addrs| {
            let _ = addrs.push(IpCidr::new(
                IpAddress::v4(
                    config::MCU_IP[0],
                    config::MCU_IP[1],
                    config::MCU_IP[2],
                    config::MCU_IP[3],
                ),
                24,
            ));
        });

        let Storage {
            socket_storage,
            udp_rx_meta,
            udp_tx_meta,
            udp_rx_data,
            udp_tx_data,
        } = store;

        let mut sockets = SocketSet::new(&mut socket_storage[..]);
        let udp_socket = udp::Socket::new(
            udp::PacketBuffer::new(&mut udp_rx_meta[..], &mut udp_rx_data[..]),
            udp::PacketBuffer::new(&mut udp_tx_meta[..], &mut udp_tx_data[..]),
        );
        let udp_handle = sockets.add(udp_socket);

        Self {
            iface,
            ethdev,
            sockets,
            udp_handle,
        }
    }

    pub fn poll(&mut self, now_ms: u32) {
        let timestamp = Instant::from_millis(now_ms as i64);
        self.iface
            .poll(timestamp, &mut self.ethdev, &mut self.sockets);

        let socket = self.sockets.get_mut::<udp::Socket>(self.udp_handle);
        while socket.can_recv() {
            let _ = socket.recv();
        }
    }

    pub fn send(&mut self, now_ms: u32, payload: &[u8]) -> SendResult {
        self.poll(now_ms);

        let socket = self.sockets.get_mut::<udp::Socket>(self.udp_handle);
        if !socket.is_open() && socket.bind(config::MCU_UDP_PORT).is_err() {
            return SendResult::BindFailed;
        }

        if !socket.can_send() {
            return SendResult::Busy;
        }

        let endpoint = IpEndpoint::new(
            IpAddress::v4(
                config::TELEMETRY_DEST_IP[0],
                config::TELEMETRY_DEST_IP[1],
                config::TELEMETRY_DEST_IP[2],
                config::TELEMETRY_DEST_IP[3],
            ),
            config::PC_UDP_PORT,
        );

        let result = match socket.send_slice(payload, endpoint) {
            Ok(()) => SendResult::Queued,
            Err(_) => SendResult::SendFailed,
        };

        self.poll(now_ms);
        result
    }
}

pub fn ring() -> &'static mut ethernet::DesRing<4, 4> {
    unsafe { &mut *addr_of_mut!(DES_RING) }
}

pub fn init_storage() -> &'static mut Storage<'static> {
    let store = addr_of_mut!(STORE).cast::<Storage<'static>>();

    unsafe {
        addr_of_mut!((*store).socket_storage).write([SocketStorage::EMPTY; 4]);
        addr_of_mut!((*store).udp_rx_meta).write([udp::PacketMetadata::EMPTY; 4]);
        addr_of_mut!((*store).udp_tx_meta).write([udp::PacketMetadata::EMPTY; 4]);
        addr_of_mut!((*store).udp_rx_data).write([0; 256]);
        addr_of_mut!((*store).udp_tx_data).write([0; 512]);

        &mut *store
    }
}
