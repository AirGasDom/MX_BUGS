#!/usr/bin/env bash
# Poll the gateway over serial and append counts since a start time to a CSV.
# Exits (so the caller notices) if ppp0 MTU is no longer the expected value,
# the gateway rebooted, serial fails 3 times in a row, or END_UTC is reached.
#
# Usage: mtu_monitor.sh <csv> <start MMDDHHMMSS UTC> <end ISO UTC> [interval_s] [expected_mtu]
set -u
CSV=$1 START=$2 END_UTC=$3 INTERVAL=${4:-900} WANT_MTU=${5:-1400}
GW="$(dirname "$0")/gw.py"
END_S=$(date -u -d "$END_UTC" +%s)

read -r -d '' REMOTE <<EOF
L=\$(ls /var/log/concentrator.log* | grep -v gz); echo "M""ON,\$(cat /sys/class/net/ppp0/mtu 2>/dev/null || echo down),\$(ip -br addr show ppp0 2>/dev/null | awk '{print \$3}' | cut -d/ -f1),\$(cut -d. -f1 /proc/uptime),\$(awk -v S=$START 'BEGIN{split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec",M," ");for(i in M)N[M[i]]=i} {t=\$4;gsub(":","",t);k=sprintf("%02d%02d%s",N[\$2],\$3,t)} k>=S{if(/Sock Recv ERROR/)e++;if(/SW Reseting/)r++;if(/Reading PUSHED TO ACS/)p++;if(/NOT PUSHED TO ACS/)np++;if(/Failed SSL connect/)s++} END{print e+0","r+0","p+0","np+0","s+0}' \$L)"
EOF

[ -s "$CSV" ] || echo "check_utc,window_start_utc,ppp0_mtu,ppp0_ip,uptime_s,sock_recv_err,resets,pushed,not_pushed,ssl_fail" > "$CSV"
fails=0 last_up=0
while :; do
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  row=$(python3 "$GW" "$REMOTE" 60 2>&1 | grep -a '^MON,' | tail -1)
  if [ -z "$row" ]; then
    fails=$((fails+1)); echo "$now,$START,serial_error,,,,,,," >> "$CSV"
    [ $fails -ge 3 ] && { echo "STOP: serial failed 3 times in a row"; exit 2; }
  else
    fails=0
    IFS=, read -r _ mtu ip up rest <<< "$row"
    echo "$now,$START,$mtu,$ip,$up,$rest" >> "$CSV"
    echo "$now mtu=$mtu ip=$ip up=$up err,resets,pushed,not_pushed,ssl=$rest"
    [ "$mtu" != "$WANT_MTU" ] && { echo "STOP: ppp0 MTU is $mtu, expected $WANT_MTU"; exit 3; }
    [ "$up" -lt "$last_up" ] && { echo "STOP: gateway rebooted (uptime $up < $last_up)"; exit 4; }
    last_up=$up
  fi
  [ "$(date -u +%s)" -ge "$END_S" ] && { echo "DONE: reached $END_UTC"; exit 0; }
  sleep "$INTERVAL"
done
