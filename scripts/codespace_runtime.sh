#!/usr/bin/env bash
set -u
log(){ printf '[NEXUS-CLOUD] %s\n' "$*"; }

# SSH fallback: the devcontainer feature should provide this, but make it self-healing.
if ! command -v sshd >/dev/null 2>&1; then
  log 'installing openssh-server fallback'
  sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openssh-server || true
fi
if command -v sshd >/dev/null 2>&1; then
  sudo mkdir -p /run/sshd
  sudo ssh-keygen -A >/dev/null 2>&1 || true
  pgrep -x sshd >/dev/null 2>&1 || sudo /usr/sbin/sshd || true
fi

# noVNC fallback: only install/start if desktop-lite did not already expose 6080.
if ! ss -ltn 2>/dev/null | grep -q ':6080 '; then
  if ! command -v Xvfb >/dev/null 2>&1 || ! command -v x11vnc >/dev/null 2>&1 || ! command -v websockify >/dev/null 2>&1; then
    log 'installing lightweight noVNC fallback'
    sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq xvfb fluxbox x11vnc novnc websockify || true
  fi
  if command -v Xvfb >/dev/null 2>&1 && command -v x11vnc >/dev/null 2>&1 && command -v websockify >/dev/null 2>&1; then
    export DISPLAY=:1
    pgrep -f 'Xvfb :1' >/dev/null 2>&1 || nohup Xvfb :1 -screen 0 1600x900x24 -nolisten tcp >/tmp/nexus-xvfb.log 2>&1 &
    sleep 1
    pgrep -x fluxbox >/dev/null 2>&1 || nohup fluxbox >/tmp/nexus-fluxbox.log 2>&1 &
    pgrep -f 'x11vnc.*5901' >/dev/null 2>&1 || nohup x11vnc -display :1 -forever -shared -nopw -rfbport 5901 >/tmp/nexus-x11vnc.log 2>&1 &
    if ! ss -ltn 2>/dev/null | grep -q ':6080 '; then
      nohup websockify --web=/usr/share/novnc 6080 localhost:5901 >/tmp/nexus-novnc.log 2>&1 &
    fi
  fi
fi

log "sshd=$(pgrep -x sshd >/dev/null 2>&1 && echo up || echo down) novnc=$(ss -ltn 2>/dev/null | grep -q ':6080 ' && echo up || echo down)"
exit 0
