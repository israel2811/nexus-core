#!/usr/bin/env bash
set +e
CONF=/etc/nexus-offload.conf
[ -r "$CONF" ] && . "$CONF"
KEY=${NEXUS_WINDOWS_KEY:-}
WIN_USER=${NEXUS_WINDOWS_USER:-}
EXPECTED_HOST=${NEXUS_WINDOWS_EXPECTED_HOST:-}
DEFAULT_HOST=${NEXUS_WINDOWS_HOST:-}
PORT=${NEXUS_BROKER_PORT:-8765}
LAST_IP_FILE=/var/lib/nexus/windows-ip
LOG=/var/log/nexus/offload-tunnel.log

log(){ printf "%s %s\n" "$(date -Is)" "$*" >>"$LOG"; }
probe(){
  local ip="$1" out
  [ -n "$ip" ] && [ -n "$KEY" ] && [ -n "$WIN_USER" ] && [ -n "$EXPECTED_HOST" ] || return 1
  out=$(ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=4 -o StrictHostKeyChecking=accept-new "$WIN_USER@$ip" hostname 2>/dev/null | tr -d '\r')
  [ "${out^^}" = "${EXPECTED_HOST^^}" ] || return 1
  printf "%s" "$ip"
}

mkdir -p /var/log/nexus
log "offload_reverse_tunnel_start"
while :; do
  HOST=""
  [ -r "$LAST_IP_FILE" ] && HOST=$(cat "$LAST_IP_FILE" 2>/dev/null)
  HOST=$(probe "$HOST")
  [ -z "$HOST" ] && HOST=$(probe "$DEFAULT_HOST")
  if [ -z "$HOST" ]; then
    log "windows_not_available_or_config_incomplete"
    sleep 10
    continue
  fi
  log "connecting host=$HOST"
  ssh -N -T -i "$KEY" \
    -o BatchMode=yes \
    -o ExitOnForwardFailure=yes \
    -o ConnectTimeout=6 \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    -o StrictHostKeyChecking=accept-new \
    -R "127.0.0.1:${PORT}:127.0.0.1:${PORT}" \
    "$WIN_USER@$HOST" >>"$LOG" 2>&1
  rc=$?
  log "tunnel_exit rc=$rc host=$HOST"
  sleep 5
done
