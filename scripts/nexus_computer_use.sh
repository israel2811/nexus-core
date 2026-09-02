#!/usr/bin/env bash
set -euo pipefail
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/root/.Xauthority}"
if [[ -z "${XAUTHLOCALHOSTNAME:-}" ]]; then
  auth_file="$(ps -eo args | sed -n 's/.*[X]org .* -auth \([^ ]*\).*/\1/p' | head -1)"
  if [[ -n "$auth_file" && -r "$auth_file" ]]; then
    auth_host="$(xauth -f "$auth_file" list 2>/dev/null | awk 'NR==1{split($1,a,"/"); print a[1]}')"
    [[ -n "$auth_host" ]] && export XAUTHLOCALHOSTNAME="$auth_host"
  fi
fi
outdir="${NEXUS_CU_DIR:-/run/nexus-computer-use}"
mkdir -p "$outdir"
cmd="${1:-status}"
case "$cmd" in
  status)
    echo "DISPLAY=$DISPLAY"
    echo "XAUTHORITY=$XAUTHORITY"
    echo "XAUTHLOCALHOSTNAME=${XAUTHLOCALHOSTNAME:-}"
    xdotool getactivewindow getwindowname
    ;;
  screenshot)
    file="${2:-$outdir/screen.png}"
    import -display "$DISPLAY" -window root "$file"
    identify "$file" | head -1
    ;;
  windows)
    xdotool search --onlyvisible --name '.*' getwindowname %@ 2>/dev/null
    ;;
  move)
    xdotool mousemove --sync "$2" "$3"
    ;;
  click)
    xdotool click "${2:-1}"
    ;;
  type)
    shift
    xdotool type --clearmodifiers --delay 20 -- "$*"
    ;;
  key)
    shift
    xdotool key --clearmodifiers "$@"
    ;;
  *)
    echo "usage: $0 status|screenshot [file]|windows|move X Y|click [button]|type TEXT|key KEYS..." >&2
    exit 2
    ;;
esac
