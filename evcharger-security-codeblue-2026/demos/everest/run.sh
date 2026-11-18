#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
M=ev-manager-1
OUT=captures/$(date +%Y%m%d-%H%M%S)
mkdir -p "$OUT"
SESSION='sleep 1;iso_wait_slac_matched;iso_start_v2g_session DC 86400 0;iso_wait_pwr_ready;sleep 10;iso_stop_charging;iso_wait_v2g_session_stopped;unplug'

clean_log() { docker exec $M sh -c "sed 's/\x1b\[[0-9;]*m//g' /tmp/manager.log"; }

docker compose -p ev -f docker-compose.iso15118-dc.yml up -d --wait
docker exec $M pkill -f manager || true
docker cp config-sil-dc.yaml $M:/ext/source/config/config-sil-dc.yaml
docker exec -d $M sh -c 'sh /ext/build/run-scripts/run-sil-dc.sh > /tmp/manager.log 2>&1'
until clean_log 2>/dev/null | grep -q 'Ready to start charging'; do sleep 1; done

docker rm -f ev-cap >/dev/null 2>&1 || true
docker run -d --rm --name ev-cap --net container:$M -v "$PWD/$OUT:/cap" nicolaka/netshoot \
  tcpdump -i any -U -w /cap/v2g.pcap ip6 >/dev/null
sleep 2
echo "[*] plugging in the simulated car"
docker exec ev-mqtt-server-1 mosquitto_pub -t everest_external/nodered/1/carsim/cmd/execute_charging_session -m "$SESSION"

for _ in $(seq 90); do clean_log | grep -q 'SessionStopRes' && break; sleep 1; done
sleep 2
docker stop ev-cap >/dev/null

clean_log | grep -a -o -E '(Message to encode|Decoded message) \(ns=[^)]*\): \{.*' \
  | sed -E 's/^Message to encode \(ns=[^)]*\): /EV   -> /; s/^Decoded message \(ns=[^)]*\): /EVSE -> /' \
  > "$OUT/transcript.txt"

echo "[+] $OUT/v2g.pcap"
echo "[+] $OUT/transcript.txt"
clean_log | grep -a -E "TLS server on .* listening|SDP requested" | sed -E "s/^.*:: //" | sort -u
grep supportedAppProtocol "$OUT/transcript.txt"
echo "[+] $(wc -l < "$OUT/transcript.txt") V2G messages, all plaintext EXI"
