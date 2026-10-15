#!/usr/bin/env bash
# NEXUS Codespaces runtime: never auto-expose unauthenticated remote desktop.
set -euo pipefail
log() { printf '[NEXUS-CLOUD] %s\n' "$*"; }

# The official devcontainer SSH feature should supply sshd; do not install
# packages at every start or expose additional ports automatically.
if command -v sshd >/dev/null 2>&1; then
  if ! pgrep -x sshd >/dev/null 2>&1; then
    sudo mkdir -p /run/sshd
    sudo /usr/sbin/sshd || log 'SSHD startup unsuccessful; GitHub CLI SSH remains preferred'
  fi
else
  log 'No sshd present; use GitHub Codespaces connection facilities'
fi

if command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ':6080 '; then
  log 'Desktop-lite already serves noVNC; keep its forwarded port PRIVATE'
  exit 0
fi

# Private VNC is opt-in only, with a VNC password stored outside the repository.
if [[ "${NEXUS_ENABLE_PRIVATE_VNC:-0}" != "1" ]]; then
  log 'Private VNC fallback disabled; set NEXUS_ENABLE_PRIVATE_VNC=1 after secure setup'
  exit 0
fi

passwd_file="$HOME/.vnc/passwd"
if [[ ! -s "$passwd_file" ]] || [[ -n "$(find "$passwd_file" -perm /077 -print)" ]]; then
  log 'Private VNC refused: missing password file or excessively broad permissions'
  exit 1
fi

for app in Xvfb x11vnc websockify fluxbox; do
  command -v "$app" >/dev/null 2>&1 || { log "Missing $app; no auto-install"; exit 1; }
done

export DISPLAY=:1
pgrep -f 'Xvfb :1' >/dev/null 2>&1 || nohup Xvfb :1 -screen 0 1600x900x24 -nolisten tcp >/tmp/nexus-xvfb.log 2>&1 &
sleep 1
pgrep -x fluxbox >/dev/null 2>&1 || nohup fluxbox >/tmp/nexus-fluxbox.log 2>&1 &
pgrep -f 'x11vnc.*5901' >/dev/null 2>&1 || nohup x11vnc -display :1 -forever -shared -localhost -rfbauth "$passwd_file" -rfbport 5901 >/tmp/nexus-x11vnc.log 2>&1 &
if ! ss -ltn 2>/dev/null | grep -q '127.0.0.1:6080 '; then
  nohup websockify --web=/usr/share/novnc 127.0.0.1:6080 127.0.0.1:5901 >/tmp/nexus-novnc.log 2>&1 &
fi
log 'Private VNC fallback started on loopback only; no public port forwarding'
