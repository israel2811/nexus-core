#!/usr/bin/env bash
set -euo pipefail

log() { printf '[NEXUS-CLOUD] %s\n' "$*"; }

# Deliberately never create a second VNC/noVNC endpoint.
# desktop-lite in devcontainer.json is responsible for the browser desktop.
# GitHub forwarded ports must remain PRIVATE and authenticated.
if command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ':6080 '; then
  log "desktop-lite web desktop detected on port 6080; keep forwarded port private"
else
  log "desktop-lite port 6080 is not listening; no insecure VNC fallback will be started"
fi

# SSH is provided by the official devcontainer sshd feature.
# Do not generate or display keys here, and do not install packages on startup.
if command -v sshd >/dev/null 2>&1; then
  log "sshd installed via devcontainer feature"
else
  log "sshd unavailable; review devcontainer feature setup before attempting SSH"
fi

# Fail closed: no x11vnc -nopw, websockify or Xvfb launched from this script.
exit 0
