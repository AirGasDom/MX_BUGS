# Bench setup (Raspberry Pi ↔ MaxGateway)

## Ethernet
- Pi `eth0` = `192.168.50.1/24` static (`/etc/systemd/network/10-eth0-static.network`), unmanaged by NetworkManager.
- DHCP and DNS on eth0 are served by dnsmasq (`/etc/dnsmasq.d/lan.conf`, range `.100`–`.200`, 12h leases).
- The gateway (MAC `00:10:ec:02:08:6b`) gets `192.168.50.180`. It also has `.181` as a static/secondary address.
- 2026-10-19: dnsmasq failed at boot with "unknown interface eth0".
  Fixed by changing `bind-interfaces` to `bind-dynamic` in `/etc/dnsmasq.conf` (backup `/etc/dnsmasq.conf.bak-2026-10-19`).
- The Pi does not NAT eth0 traffic, yet dnsmasq advertises `192.168.50.1` as the router.
  The gateway's ppp0 default route has a lower metric and wins, so this is harmless today.

## Serial console
- `/dev/ttyUSB0` (Silicon Labs CP2102N), 115200 baud: `picocom -b 115200 /dev/ttyUSB0`
- Scripted: `GW_PASS=... python3 ../tools/gw.py '<command>' [timeout]`. Close picocom first, because only one program can use the port.
- No SSH or HTTP is listening on the gateway (ports 22/2222/80/443 are closed), so serial is the only way in.
