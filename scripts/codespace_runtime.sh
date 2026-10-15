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

# Never launch anonymous VNC or install UI services during remote compute.
# Keep GitHub forwarded ports PRIVATE; enable desktop-lite only after authenticating.
if ! ss -ltn 2>/dev/null | grep -q ':6080 '; then
  log 'No VNC desktop exposed; SSH-only NEXUS offloading mode.'
fi

log "sshd=$(pgrep -x sshd >/dev/null 2>&1 && echo up || echo down) novnc=$(ss -ltn 2>/dev/null | grep -q ':6080 ' && echo up || echo down)"
exit 0
