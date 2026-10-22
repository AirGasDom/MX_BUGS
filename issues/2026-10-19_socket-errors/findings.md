# Socket errors on MaxGateway / CellConcentrator 0010EC02086B

**Status:** open. **The reflash did not fix it:** the same errors and resets continue on app V 1.01.07.
A cellular MTU limit is confirmed. The MTU 1400 test was cut short (unit taken off the bench at 18:30 UTC).
**Plan (2026-10-20):** recommend replacing the SIM in 086B and retesting; see Next steps.
**Opened:** 2026-10-19 · **Last updated:** 2026-10-20

> **2026-10-20, reflash:** the user is having the unit reflashed.
> - The reflash wipes the temporary `ppp0 mtu 1400` change, so the evening busy-period test in Next steps will not run on the current image.
> - Gateway logs up to 07:37 are saved under `logs/gateway/`. Anything the gateway logs after 07:37 is lost if `/var/log` is wiped.
> - After the reflash, recheck: app version, ppp0 MTU (`ip link show ppp0`), the path MTU ping test,
>   and the `Sock Recv ERROR` count, especially from 17:00 to 22:00. Compare against the table below.
>   If the errors come back, apply the MTU fix and run the evening test as written in Next steps.

## After the reflash (2026-10-20)

Source: `logs/0010EC02086B Log 20261020.txt`, diagnostic app capture (user-supplied).
It covers 14:04 to 16:15 UTC (10:04 to 12:15 EDT). The capture prints every line twice; the counts below use lines with duplicates removed.

- **App version is now V 1.01.07** (Build 05), up from 1.01.03.
- **The symptom is unchanged:** `Sock Recv ERROR` → `Error 51` → `Error [7]` → `Too many failed sockets 11` → `SW Reseting... Type=10` → app restart.
- Uplink is still `ppp0`, with a new IP `10.104.90.175`.
- **The reflashed image runs on UTC** (`/etc/localtime -> Universal`); the clock itself is correct.
  The pre-reflash logs were in EDT (their file times match local rotation at 00:00 EDT).
  So this capture is 10:04 to 12:15 EDT: midday, not the evening busy period.

| Hour (UTC) | Sock Recv ERROR | App resets | Readings pushed | SSL fails |
|---|---:|---:|---:|---:|
| 14 (from 14:04) | 57 | 2 | 2 | 0 |
| 15 | 67 | 3 | 4 | 1 |
| 16 (to 16:15) | 10 | 0 | 0 | 0 |

Resets at 14:33, 14:56, 15:02, 15:33 and 15:52 UTC.
The error rate (about 60/hr) is lower than the 10-19 evening (100 to 120/hr) but far above the clean overnight period (0 to 4/hr).

New in this log: one `Address Not Found!` at 14:34, a likely DNS lookup failure. It does not appear in the earlier logs.
`Send to API Queue failed` and `Error, Mote PwrUp response` also appear here, but they were already in the earlier logs.

### Bench checks after the reflash (2026-10-20, 18:16 UTC / 14:16 EDT)

- App V 1.01.07 confirmed; last boot 17:59:21 UTC.
- ppp0 `10.104.231.65`, **MTU back to 1500** (the reflash removed the earlier temporary change).
- eth0 shows NO-CARRIER (Ethernet cable not connected); serial only.
- **Path MTU is unchanged:** packets up to 1444 bytes get replies and 1448 bytes and above get none, on both `204.16.110.235` and `72.249.131.173`.
  There was occasional single-packet loss below the limit (for example 1428 bytes to `72.249.131.173`).
- Baseline before the change, 17:59 to 18:17 UTC: 10 `Sock Recv ERROR`, 0 resets, **0 readings pushed**, 0 SSL fails.

**Change applied:** `18:17:18 UTC  ip link set ppp0 mtu 1400`, NOT persistent (it reverts when ppp0 reconnects or the gateway reboots).
To compare, count from 18:17:18 UTC onward in `/var/log/concentrator.log`.

### MTU 1400 retest (2026-10-21)

Unit 086B back on the bench, serial only. Before the change (14:16 UTC):
- App V 1.01.07, up 18 h 11 m. ppp0 `10.100.58.124`, MTU 1500.
- **Same SIM** (IMSI `310410268702058`), LTE Cat-M1, LAC `1547`, Cell `13321745`, Strength 100.
- Path MTU unchanged: 1444-byte packets get replies, 1448 bytes and above get none, on both ACS IPs.
- `concentrator.log` (UTC, from 00:00) per hour, Sock Recv ERROR / resets: 08 0/0, 09 0/0, 10 1/0, 11 6/1, 12 19/3, 13 3/0, 14 (to 14:16) 3/1.
- `PUSHED` does not appear anywhere in today's log (0 lines), so push counts can't be compared yet. Check why before judging the result.

**Change applied:** `14:17:39 UTC  ip link set ppp0 mtu 1400`, NOT persistent. 1400-byte pings to both ACS IPs succeed.
Count from 14:17:39 UTC onward. The evening busy period is 21:00 to 02:00 UTC.
Monitor: `../../tools/mtu_monitor.sh`, every 15 min until 03:00 UTC 10-22, to `logs/mtu1400-monitor-20261021.csv`.

**Status at 17:00 UTC (2 h 40 m in), encouraging but not conclusive:**
- 11 checks, all clean: MTU still 1400, same ppp0 IP, no reboot.
- Since the change: 0 `Sock Recv ERROR`, 0 resets, 0 SSL fails. Before it, 12:00 to 14:17 UTC had 25 errors and 4 resets.
- The traffic is the ACS message poll (`Getting messages from ACS` → `No (more) messages from ACS`), every 15 min, done in 2 to 5 s. About 11 clean polls in a row.
- **No readings are sent at all:** 0 `Reading PUSHED TO ACS!` and 0 `NOT PUSHED` all day, so the larger upload path is untested.
- The SmartMesh manager link resets and reconnects about every 5 min (27 `Smartmesh API - Reset()` since 14:17).
  Not yet known whether that is normal with no motes on the bench, or a separate fault that keeps readings from arriving.
- The real test is still the 21:00 to 02:00 UTC busy period (100+ errors/hr on 10-19).

**Status at 20:40 UTC (6 h 20 m in):** still clean. Counted per ACS poll (a poll fails if any `Sock Recv ERROR` or `Failed SSL connect` follows it before the next poll), today's log:

| Window (10-21 UTC) | ppp0 MTU | Polls | Failed polls |
|---|---|---:|---:|
| 00:00 to 14:17 | 1500 | 61 | 28 (46%) |
| 14:17 to 20:40 | 1400 | 26 | 0 |

At the before-change failure rate, 26 clean polls in a row would be very unlikely. Failures do cluster by time of day, though (04:00 to 10:00 UTC was quiet even at 1500), so the evening still has to be checked.
**Best like-for-like baseline:** 10-21 00:00 to 01:00 UTC (20:00 to 21:00 EDT on 10-20) had MTU 1500 (the 20:05 UTC reboot reverted the change), no motes and 6 polls, and logged **43** `Sock Recv ERROR`. Compare tonight's 00:00 UTC hour against it.

**Final result (monitor ended 2026-10-22 03:03 UTC, 12 h 45 m at MTU 1400):** 0 `Sock Recv ERROR`, 0 resets, 0 SSL fails.
MTU stayed 1400 and ppp0 IP `10.100.58.124` was unchanged, with no reboot. This covers the full evening busy period, 21:00 to 02:00 UTC, including the 00:00 UTC hour (43 errors at MTU 1500 the night before).
The fix holds for the ACS poll path. The reading-upload path is still untested (no motes joined). Next: restore the bench mote, then make the MTU or MSS change persistent (Next steps, step 2).

### MTU 1500 control run (2026-10-22)

Purpose: confirm the MTU is the cause before any fleet-wide fix. If the errors come back at 1500 and stop again at 1400, the link is causal on this unit.
Still open: whether the 1444-byte limit is specific to this SIM, APN or cell, and why there are few field complaints (see the scope questions below).

**Change applied:** `11:06:24 UTC  ip link set ppp0 mtu 1500`. Gateway up 1 d 15 h, same SIM, ppp0 `10.100.58.124`, still no motes.
Before it: no errors or resets for 20 h 49 m at MTU 1400 (14:17:39 UTC 10-21 to 11:06 UTC 10-22).
Monitor: `logs/mtu1500-control-20261022.csv`, every 15 min until 03:00 UTC 10-23; it stops if the MTU leaves 1500 or the gateway reboots.
Expectation if MTU is the cause: about 46% of polls fail, as on 10-21 before the change, plus type 9/10 resets.

### Why no readings today, and why the 10-19 numbers are not comparable hour for hour

- **No motes are joined today.** `comm_SendDustCmdTask` (`comm.c:5498`) resets the SmartMesh manager when `g_numMotesConnected` has been 0 for 360 s.
  That is the ~6-minute `Smartmesh API - Reset()` cycle. It is a symptom of no motes, not a fault.
  On 10-19/10-20 motes were present (a Pressure Mote, MAC `00:17:0D:00:00:70:D9:E6`; 21 + 85 `Reading PUSHED TO ACS!`) and the manager hardly reset (2 resets).
  So the bench pressure mote is off, out of range, or joined elsewhere. Restore it to retest the reading-upload path.
  (Commit `fbfe08b` notes the same no-mote reset cycle from 2022 testing.)
- **The failing transaction was the ACS message poll, not reading uploads.** On 10-19, 663 of 666 `Sock Recv ERROR` followed `Getting messages from ACS`; 3 followed a reading push.
  So today's polls exercise the same path that failed.
- **Poll rate differs by app version.** On 10-19 (V1.01.03) the app polled 59 to 75 times/hr (about every 55 s); today (V1.01.07) it polls 4/hr.
  Commit `27af76d` (2022-10-04, "Slowed getting messages from ACS") defined `SMS_2_GET_MESSAGE`, which fixes the poll period at `g_getMessagesDefaultPeriod` = 900 s.
  Before that, the app polled every 30 s for an hour after startup or after any ACS message (`comm.c:5524-5537`).
  On V1.01.03 that made a loop: failures → `Too many failed sockets 11` → app restart → 30 s polling for an hour → more failures → restart.
  This explains the 8 to 15 minute reset cycle and why 10-19 had about 100 errors/hr. V1.01.07 polls less, so it fails and resets less often, but the underlying failure (46% of polls at MTU 1500) is the same.

## Symptom

Concentrator app V 1.01.03 (`/usr/bin/Concentrator`) logs repeated:

```
Error *: Sock Recv ERROR
Info  *: Displaying Error 51
Error *: Error [7], Reading response.        (once: Error [5])
Info  *: No (more) messages from ACS
Error *: Too many failed sockets 11|12       -> "SW Reseting... Type=10", app restarts
Error *: Failed SSL connect! Ver=0           (occasional)
```

When the failures pile up, the app restarts itself about every 8 to 15 minutes.
While that is happening, sensor readings mostly fail to upload (`Reading PUSHED TO ACS!` stops).

## What the errors mean (from source)

Source: `CellularConcentratorApp/` (git HEAD `39f1ee9`, V1.01.08b0, 2023-03-21; the units run V1.01.03 / V1.01.07). All in `src/comm.c` `SendToInfrastructure()` unless noted.

| Log line | Meaning |
|---|---|
| `Sock Recv ERROR` | TCP and TLS connected and `SSL_write` succeeded, but `SSL_read` returned **0 bytes in total** (`comm.c:2178`). The socket has a **10 s receive timeout** (`SO_RCVTIMEO`, `comm.c:1878`), so the server's reply did not arrive within 10 s. |
| `Displaying Error 51` | LCD code `ERR_SOCKET` = E51 (`lcd/lcd.h`), set on any socket failure. |
| `Error [7], Reading response` | `comm_eResponseResult_t` 7 = `COMM_SOCKT_RECV_FAIL` (same failure as above). `Error [5]` = `COMM_SOCKT_CONNECT_FAIL` (TLS connect failed). |
| `Failed SSL connect! Ver=0` | `SSL_connect` failed; `Ver=0` means certificate verification was not the cause (`X509_V_OK`). |
| `Too many failed sockets 11` | `uiFailedSocketComm > 10`: **11 failures in a row** with no successful exchange in between (`comm.c:2266`). The counter resets on any good reply. |
| `SW Reseting... Type=10` | `DoSwReset(SOCKET_ERRS)`; `SOCKET_ERRS` = 0x0A = 10 (`main.h`). |

So every failure is "request sent, no reply within 10 s". That fits the MTU finding: the server's full-size reply packets (or retransmissions of them) never arrive, and TCP cannot recover inside the 10 s window.
It also gives a mechanism for the time-of-day pattern: anything that delays the reply (cell congestion, retransmission back-off, server load) pushes it past 10 s.

## Setup

| Item | Value |
|---|---|
| ACS server | `bam.airgas-rd.com:443` (from `/etc/concentrator/concentrator.conf`) |
| ACS DNS A records | `72.249.131.173`, `204.16.110.235` (the app uses either) |
| Uplink used | `ppp0` cellular (AT&T via ofono), default route, `10.101.121.37` (was `10.103.11.34` on 10-19 afternoon) |
| eth0 | `192.168.50.180` (DHCP from Pi) + `192.168.50.181` (static/secondary). Not used for ACS traffic. |
| Console | `/dev/ttyUSB0` on the Pi (CP2102N), 115200 8N1, see `../../tools/gw.py` |
| App log on gateway | `/var/log/concentrator.log` (rotated daily at 00:00) |

### Modem and SIM (read 2026-10-20, 18:24 UTC, from ofono)

| Item | Value |
|---|---|
| Modem | Telit ME910C1-WW (USB `1bc7:1101`), firmware `M0B.800004` |
| IMEI | `353081090891972` |
| SIM IMSI | `310410268702058` (AT&T, MCC 310 / MNC 410). ICCID is not exposed by ofono. |
| Network | AT&T, **LTE Cat-M1**, registered, Strength=100, roaming off |
| Cell | LAC `1547`, Cell ID `13321745` |
| APN | `30304.mcs` (private APN), CHAP, IPv4 only |
| DNS | `147.160.47.13`, `147.160.47.14` (from the APN) |
| ppp0 owner | **ofono** (context1, Method=static). No pppd runs, so `/etc/ppp/peers/airgas` is not used. |

LTE Cat-M1 is a low-bandwidth network type, so cell-site congestion at busy times is plausible.
To tell a unit fault from a SIM/APN or cell fault, compare these values with a good unit, or swap SIMs.

### Comparison units on the bench (2026-10-20)

| Unit | App | Modem / FW | SIM IMSI | APN | Cellular state |
|---|---|---|---|---|---|
| **0010EC02086B** (problem unit) | V1.01.07 | ME910C1-WW / M0B.800004 | 310410268702058 | `30304.mcs` | registered, LTE Cat-M1, Strength 100 |
| 0010EC01DB1C | V1.01.07 | ME910C1-WW / M0B.800004 | 310030006918135 | none set | unregistered, 3 min after boot; console then lost (serial adapter hung) |
| 0010EC020853 | not running (last log Jun 3) | modem not enumerated (ofono not started) | n/a | n/a | not usable without starting the app |
| 0010EC02229B | V1.01.07 | ME910C1-WW / M0B.800004 | 310410268702004 (same batch) | `30304.mcs` | **searching**, never attached in 9 min; app cycles modem power every ~5 min |

Modem, firmware and app version are identical, so they cannot explain one unit failing.

**Full ofono settings, 0010EC02086B vs 0010EC02229B (15:43 EDT):** identical apart from identity and live network state.
Same: modem model, firmware, USB path, ofono interfaces and features, SMS centre `+13123149810`, SMS bearer `cs-preferred`,
roaming not allowed, registration mode `auto-only`, SIM MCC/MNC 310/410, no PIN, retry counts, APN `30304.mcs`, CHAP, IPv4.
Different: IMEI, IMSI, and the live state (02229B was still `searching` 20 min after boot even with its antenna connected).
Not readable via ofono: band and network-type (RAT) settings; `get-tech-preference` fails because this ofono build has no RadioSettings interface.
Config checksums on 02229B (to compare with 02086B when it is back): `concentrator.conf` `9e3115ff…`, `/var/lib/connman/settings` `021a6daf…`.
No comparison unit has reached the network yet, so the 1444-byte path test has not been run on a second unit.

## Timeline from gateway logs (hourly)

From `logs/gateway/`; all times EDT.

| Hour | Sock Recv ERROR | App resets | Readings pushed | SSL fails |
|---|---:|---:|---:|---:|
| 10-19 17 | 103 | 9 | 1 | 10 |
| 10-19 18 | 121 | 12 | 2 | 3 |
| 10-19 19 | 103 | 10 | 0 | 1 |
| 10-19 20 | 120 | 8 | 0 | 5 |
| 10-19 21 | 103 | 6 | 2 | 1 |
| 10-19 22 | 77 | 2 | 4 | 3 |
| 10-19 23 | 39 | 0 | 12 | 0 |
| 10-20 00 to 05 | 0 to 4 | 0 | 12/hr | 0 |
| 10-20 06 | 18 | 0 | 8 | 0 |
| 10-20 07 (to 07:37) | 14 | 0 | 5 | 0 |

The earlier capture `logs/0010EC02086B Log 20261019.txt` (14:06 to 14:42) shows the same pattern: 4 app restarts in 36 minutes.

**Key observation:** the failures depend on time of day. They are heavy in the evening, nearly absent from 23:00 to 06:00, and return from 06:00.
The cellular IP stayed the same (`10.101.121.37`) through both the bad period and the clean period. Both server IPs appear in both periods.

## Tests run (2026-10-20)

1. **HTTPS reachability over ppp0 (curl, both IPs):** OK. TCP connect took 0.23 to 0.34 s, the TLS handshake finished by 1.5 to 1.7 s, and the server returned HTTP 301.
   Basic connectivity, DNS and TLS all work.
2. **Live socket state (07:28):** the app's connection `10.101.121.37:57286 -> 204.16.110.235:443` had **Send-Q 2098 bytes** unacknowledged.
   It then went to `FIN_WAIT1` with 2123 bytes still queued. Data was leaving and never being acknowledged.
3. **Path MTU via ppp0 (ping payload sizes, BusyBox ping, no DF bit):**
   | Payload | Packet size | Result |
   |---|---|---|
   | 1200 to 1412 | ≤ 1440 | replies |
   | 1416 | 1444 | replies |
   | 1420 to 1472 | ≥ 1448 | **no replies** |

   **The path drops IP packets larger than 1444 bytes, but ppp0 is set to MTU 1500.**
   Full-size TCP segments (1500 bytes) are therefore lost silently. That matches a stuck Send-Q and failed receives.

## Change applied

```
07:30:37  ip link set ppp0 mtu 1400        # on gateway, NOT persistent
```

This reverts when ppp0 reconnects or the gateway reboots. To undo it by hand: `ip link set ppp0 mtu 1500`.

**Result so far:** the 07:34 push succeeded with no receive errors before it. Every push from 07:19 to 07:29 had errors before it.
That is one clean cycle during a busy period, which is encouraging but **not conclusive**.

## Open questions and caveats

- **The MTU limit does not explain the time-of-day pattern.** A fixed 1444-byte limit would cause failures around the clock.
  Yet overnight, with MTU 1500, pushes succeeded 12/12 per hour. Possible explanations:
  - most overnight traffic fits under 1444 bytes, and the large requests that fail (polls, bigger replies) happen more often in busy periods; or
  - the carrier's path MTU or its congestion changes with load (evening busy hour on the cell site).
- Signal strength looks fine (`Service AT&T Strength=100`), so weak signal is unlikely.
- The error codes are now decoded from source; see "What the errors mean (from source)".

## Next steps

0. **Replace the SIM in 086B and retest** (recommended 2026-10-20). Current SIM IMSI `310410268702058`.
   The new SIM will most likely use the same APN (`30304.mcs`) on AT&T Cat-M1. If the 1444-byte limit is in the APN or carrier path,
   a new SIM will hit it too, so judge the retest by the ping test as well as the error count.

   Retest checklist after the swap:
   - Before the app has run long: record the new IMSI, LAC / Cell ID and Strength (`list-modems`), and confirm ppp0 is at MTU 1500
     (a reboot clears any temporary 1400 setting, which is what this test needs).
   - Ping test to both `204.16.110.235` and `72.249.131.173`, payloads 1416 to 1472, as in "Tests run".
   - `Sock Recv ERROR`, reset and push counts over at least one evening, 17:00 to 22:00 EDT (21:00 to 02:00 UTC); compare with the 10-19 table.

   | Ping test | Errors | Conclusion |
   |---|---|---|
   | Replies above 1444 bytes | gone | The old SIM or its plan was the cause |
   | Still stops at 1444 | continue | APN or carrier path. Fix with MTU 1400 / MSS clamp (step 2) and ask AT&T about the APN MTU |
   | Still stops at 1444 | gone | Something else changed. Keep watching |

   If the swap does not settle it, run the MTU 1400 evening test (step 1) before replacing hardware.
   The first MTU 1400 attempt (18:17 UTC 10-20) had one check, at 18:19 UTC, before 086B came off the bench, so it gave no result.
1. Watch the **evening busy period (17:00 to 22:00)** with MTU 1400.
   Compare the `Sock Recv ERROR`, reset and push counts against the 10-19 table above. That is the real test.
2. If it helps, make it permanent. ofono brings up ppp0 itself (no pppd, so the peer files have no effect).
   Options: a connman/ofono hook or boot script that sets `ip link set ppp0 mtu 1400` whenever ppp0 comes up,
   or a TCP MSS clamp on ppp0 (`iptables -t mangle -A POSTROUTING -o ppp0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360`, if iptables is on the image).
3. If it does not help, capture traffic during a failure (tcpdump is not on the gateway; it could run on a Pi-side setup or be installed).
   Also raise the evening congestion with the carrier and the ACS server owner.

## Files

- `logs/0010EC02086B Log 20261019.txt`: diagnostic app capture, 10-19 14:06 to 14:42 (user-supplied)
- `logs/0010EC02086B Log 20261020.txt`: diagnostic app capture after the reflash, 10-20 14:04 to 16:15 UTC (user-supplied)
- `logs/mtu1400-monitor-20261020.csv`: MTU 1400 monitor; one check (18:19 UTC) before the unit came off the bench
- `logs/gateway/concentrator.log-20261020`: gateway log, 10-19 17:06 to 23:59
- `logs/gateway/concentrator.log`: gateway log, 10-20 00:00 to 07:37
