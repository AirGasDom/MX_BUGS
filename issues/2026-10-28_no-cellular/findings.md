# No cellular connection on MaxGateway / CellConcentrator 0010EC022247

**Status:** closed, cause found, fix not verified. **The modem board was not seated properly.**
The user reseated it on 2026-10-28; the unit then left the bench, so the fix was not confirmed on the console.
Before the fix the modem did not appear on USB at all, so ofono had no modem, connman had no Cellular technology, and the unit was online only over WiFi (`camwifi`).
**Opened:** 2026-10-28 · **Last updated:** 2026-10-28

## Symptom

No cellular connection. Seen on the bench 2026-10-28, 08:03 to 08:04 EDT, about 8 min after boot.

## Setup

| Item | Value |
|---|---|
| Unit | `CellConcentrator-0010ec022247` |
| Console | `/dev/ttyUSB1` on the Pi, 115200 8N1, already logged in as root. Scripted: `GW_PORT=/dev/ttyUSB1 python3 ../../tools/gw.py '<cmd>'` |
| Image | `/etc/version` `20230315141906`, kernel 4.14.134 (Jul 24 2020) |
| Clock | EDT (`Wed Oct 28 08:03:30 EDT 2026`) |
| Uplink | `wlan1` `192.168.201.80/22`, default via `192.168.200.1`, connman service `camwifi` (state `*AO`, online) |
| eth0 | DOWN |
| ACS server | `bamprodtest.airgas-rd.com:443` (test server; 086B uses `bam.airgas-rd.com`) |
| Mote radio | dust_manager on `/dev/ttymxc2`, power GPIO 90, reset GPIO 501 |

Raw capture: `logs/gw-0010ec022247-capture-20261028.txt`.

## Findings (2026-10-28, 08:03 to 08:04 EDT)

1. **No modem on the USB bus.** `lsusb` lists only the two EHCI root hubs.
   Working units show the Telit ME910C1-WW as USB `1bc7:1101` (see `../2026-10-19_socket-errors/findings.md`, Modem and SIM).
   dmesg has no USB device-connect line since boot; the only USB-serial lines are the generic/FTDI drivers registering at 105 s.
2. **ofono has no modem.** `ofonod` is running, but `org.ofono.Manager.GetModems` returns an empty array.
3. **connman has no Cellular technology.** Only P2P, WiFi (powered, connected), Bluetooth and Wired are listed.
4. **No pppd runs**, as on the other units (ofono owns ppp0 there). `/etc/ppp/peers/airgas` points at `/dev/ttyUSB1` on the gateway, which does not exist here; it is unused either way.
5. **The app has no log.** `/var/log` is a symlink to `/misc/log`, which does not exist.
   `/dev/mmcblk0p2` is mounted on `/misc` but holds only `lost+found` (dated Mar 15 2023, 2.7 MB used).
   So there is no `concentrator.log` to show what the app did with the modem.
   This is a second fault in its own right: the unit will keep no logs until `/misc/log` exists.
6. GPIO state at 8 min uptime: 27 out 0, 81 out 1, 82 out 1, 90 out 0, 501 out 1.
   Which GPIO powers or resets the modem is not known yet (90/501 belong to the mote radio per `concentrator.conf`).

## Log directory created, reboot (2026-10-28, 08:17 EDT)

- `08:17:05 EDT  mkdir -p /misc/log`. `/var/log -> /misc/log` now resolves. This is on the persistent `/misc` partition, so it should survive reboots.
- Rebooted (`sync; reboot`) and recorded 200 s of console output: `logs/gw-0010ec022247-boot-20261028.txt` (CRs stripped).
  It reached the login prompt. The console prints no kernel USB lines after early boot, so the boot log neither shows nor rules out the modem.
  Failed units: `conntrackd` and `1-wire filesystem FUSE mount`. Neither is related to the modem.
- The console has no autologin (`agetty` on `ttymxc0`), so later checks need a login: set `GW_PASS` for `gw.py`, or log in by hand with picocom.

## After the reboot (2026-10-28, 08:26 EDT, 7 min uptime)

The user logged in on the console by hand.
- **Logging works now:** `/var/log` has `concentrator.log`, `syslog`, `kern.log`, `daemon.log` and the other usual files.
  App log saved as `logs/concentrator-20261028-0818.log` (CRs stripped). App V 1.01.07, Build 05.
- **The modem is still missing:** `lsusb` shows only the root hubs, there are no `/dev/ttyUSB*` nodes, and dmesg has no USB device lines. ofono `GetModems` is still empty and connman still has no Cellular technology.
- The app reports `ConnmanStatus.CellularState = ST_NOT_AVAILABLE` and runs over WiFi (`camwifi`, Strength 62, wlan1 `192.168.201.80`).
- **The app never mentions the modem:** the log has no line containing "modem" and shows no modem power cycling.
  (The earlier notes say 229B cycled modem power about every 5 min.) The app may only manage the modem once ofono reports one, so it can't recover a modem that never enumerates.
- Everything else works: the dust module powers up, mote `00:17:0D:00:00:70:D9:E6` reports, and `Reading PUSHED TO ACS!` at 08:25:36 over WiFi.
- No good-unit `lsusb` is available yet: `/dev/ttyUSB0` on the Pi is now an `imx93-var-som` board, not a MaxGateway.

## Resolution (2026-10-28)

The user opened the unit and found the **modem board not seated properly**, then reseated it.
That fits the evidence: no USB device at all, and the app never trying to manage a modem.
**Not verified:** the unit is no longer on the bench, so nobody checked `lsusb` for `1bc7:1101`, ofono or cellular registration after the reseat.
If the unit comes back, check those three and confirm `CellularState` in `concentrator.log`.

Also fixed on this unit: `/misc/log` was created (08:17), so it logs now. Still open on it: it points at the test server `bamprodtest.airgas-rd.com`.

### Server "hello" on bamprodtest came over WiFi, not cellular

The unit was switched to `bamprodtest.airgas-rd.com` when it was brought in, and the server team then saw a hello from it.
That is expected, but **it does not show cellular works**: the unit reached ACS over WiFi with no modem present.
From `logs/concentrator-20261028-0818.log` (before the reseat):

| Time (EDT) | Log line | Meaning |
|---|---|---|
| 08:20:03 | `CONCENTRATOR POWER UP` | Unit announces itself at app start; most likely the server-side "hello" (not confirmed with the server team) |
| 08:20:33 | `REMOTE POWER UP` → `ACK powerup.` | Mote powerup, acknowledged |
| 08:20:38, 08:25:36 | `Reading PUSHED TO ACS!` | Mote readings accepted |

At the same time the only default route was `wlan1` (`camwifi`, `192.168.201.80`), there was no ppp0, and the app logged `CellularState = ST_NOT_AVAILABLE`.
The app uses whatever link connman has up, so hellos and readings go over WiFi when it is available.
`DN_SERIAL_ST_HELLO_SENT` (08:20:02) is a different hello: app ↔ dust (mote) module, internal to the unit.

To confirm cellular after the reseat: test with WiFi out of range or `camwifi` removed, or ask the server team for the hello's source IP
(an AT&T private APN `10.x` address means cellular; an office public IP means WiFi).

## Comparison with other bench units

| Unit | Modem on USB | ofono modem | Cellular state |
|---|---|---|---|
| 0010EC02086B | ME910C1-WW `1bc7:1101` | yes | registered, LTE Cat-M1 |
| 0010EC02229B | ME910C1-WW `1bc7:1101` | yes | searching, never attached |
| 0010EC020853 | not enumerated | no (ofono not started) | app not running |
| **0010EC022247** | **not enumerated** | **no (ofono running, no modems)** | **no cellular at all** |

Unlike 229B (modem present, can't attach) this is a level lower: the modem never reaches the USB bus.
That points to modem power/reset, the modem module or its seating, or the USB path, not the SIM, APN or coverage.

## Next steps (before the resolution; kept for the record)

1. Watch for the modem to appear: on 229B the app cycles modem power about every 5 min.
   Check `dmesg | grep -i usb` and `lsusb` again after 15+ min uptime. If `1bc7:1101` never shows, the modem is not powering up.
2. Find the modem power/reset GPIOs (compare `/sys/class/gpio` exports and values with 086B at the same uptime) and check them on this unit.
3. Open the unit: check the modem module is fitted and seated, and the SIM and antenna are in place.
4. ~~Create `/misc/log`, reboot, read `concentrator.log`~~ Done 08:17; the log has no modem messages.
   Check whether 086B's `/misc` holds anything besides `log` that this unit is missing.
5. Get a good-unit baseline: connect a working MaxGateway and record `lsusb; ls /dev/ttyUSB*`.
