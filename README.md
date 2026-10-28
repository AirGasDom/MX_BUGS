# MaxGateway issues

Unit: CellConcentrator `0010EC02086B` (app V 1.01.03), on the bench Pi via eth0 and `/dev/ttyUSB0`.

```
MaxGateway/
├── README.md                 this index
├── docs/bench-setup.md       Pi ↔ gateway wiring, network, console access
├── tools/gw.py               run a command on the gateway over serial
└── issues/
    └── <YYYY-MM-DD>_<slug>/
        ├── findings.md       symptom, tests, changes, status, next steps
        └── logs/             raw logs as captured (never edited)
```

## Issues

| Opened | Issue | Status |
|---|---|---|
| 2026-10-19 | [Socket errors / app resets](issues/2026-10-19_socket-errors/findings.md) | Open. Reflash (V 1.01.07) did not fix it; cellular MTU limit reconfirmed; next: replace SIM and retest |
| 2026-10-28 | [No cellular connection (0010EC022247)](issues/2026-10-28_no-cellular/findings.md) | Closed. Modem board not seated; reseated 10-28 (fix not verified, unit left the bench). `/misc/log` created |
