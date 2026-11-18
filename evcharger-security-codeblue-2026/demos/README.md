# Demos

Everything runs locally. Both ends are simulated, no hardware involved.

| Demo | Slide | Run |
|---|---|---|
| HomePlug default NMK | `plctool -m` | `python3 homeplug-nmk/nmk.py`, or play `homeplug-nmk/nmk.mp4`. Re-record with `vhs nmk.tape` |
| ISO 15118 / DIN over plaintext (EVerest SIL) | `downgrade` | `everest/run.sh` (Docker, ~16 GB image). Writes `captures/<ts>/v2g.pcap` + decoded `transcript.txt` |
| OCPP rogue CSMS → UpdateFirmware | `rogue-csms` | `ocpp/run.sh` (needs `uv`) |

Open `v2g.pcap` in Wireshark with the [dsV2Gshark](https://github.com/dspace-group/dsV2Gshark) plugin to see the EXI decoded.
