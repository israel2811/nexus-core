#!/usr/bin/env bash
# ==============================================================================
# NEXUS Unified Linux / Codespace Engine
# Single canonical bash interface consolidating:
# - runtime: Codespace environment configuration, secure loopback VNC & SSH fallback
# - bootstrap: Cloud agent toolchain provisioner (Codex, Qwen, Claude, etc.)
# - gui: Computer use & headless GUI control (xdotool, import, windows)
# ==============================================================================
set -euo pipefail

log() { printf '[NEXUS-LINUX] %s\n' "$*"; }

action="${1:-status}"
shift || true

case "$action" in
  # ----------------------------------------------------------------------------
  # SUBCOMMAND: RUNTIME (Codespaces self-healing runtime & secure loopback)
  # ----------------------------------------------------------------------------
  runtime)
    if command -v sshd >/dev/null 2>&1; then
      if ! pgrep -x sshd >/dev/null 2>&1; then
        sudo mkdir -p /run/sshd
        sudo /usr/sbin/sshd || log 'SSHD startup failed; GitHub CLI remains primary'
      fi
    else
      log 'No sshd found; using standard GitHub Codespaces connectivity'
    fi

    if command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ':6080 '; then
      log 'Desktop-lite serves noVNC on private port.'
      exit 0
    fi

    if [[ "${NEXUS_ENABLE_PRIVATE_VNC:-0}" != "1" ]]; then
      log 'Private VNC disabled. SSH-only offloading mode active.'
      exit 0
    fi

    passwd_file="$HOME/.vnc/passwd"
    if [[ ! -s "$passwd_file" ]] || [[ -n "$(find "$passwd_file" -perm /077 -print)" ]]; then
      log 'VNC refused: missing password file or broad permissions.'
      exit 1
    fi

    export DISPLAY=:1
    pgrep -f 'Xvfb :1' >/dev/null 2>&1 || nohup Xvfb :1 -screen 0 1600x900x24 -nolisten tcp >/tmp/nexus-xvfb.log 2>&1 &
    sleep 1
    pgrep -x fluxbox >/dev/null 2>&1 || nohup fluxbox >/tmp/nexus-fluxbox.log 2>&1 &
    pgrep -f 'x11vnc.*5901' >/dev/null 2>&1 || nohup x11vnc -display :1 -forever -shared -localhost -rfbauth "$passwd_file" -rfbport 5901 >/tmp/nexus-x11vnc.log 2>&1 &
    if ! ss -ltn 2>/dev/null | grep -q '127.0.0.1:6080 '; then
      nohup websockify --web=/usr/share/novnc 127.0.0.1:6080 127.0.0.1:5901 >/tmp/nexus-novnc.log 2>&1 &
    fi
    log 'Secure loopback VNC started.'
    ;;

  # ----------------------------------------------------------------------------
  # SUBCOMMAND: BOOTSTRAP (Agent CLI toolchain installation)
  # ----------------------------------------------------------------------------
  bootstrap)
    profile="${1:-core}"
    export PATH="$HOME/.local/bin:$PATH"
    mkdir -p "$HOME/.local/bin"
    log "Bootstrap agent profile: $profile"

    if command -v npm >/dev/null 2>&1; then
      npm install -g @openai/codex opencode-ai @qwen-code/qwen-code@latest
    fi

    if [[ "$profile" == "full" ]]; then
      command -v npm >/dev/null 2>&1 && npm install -g @kilocode/cli cline @charmland/crush
      python3 -m pip install --user --upgrade aider-chat || true
      command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | bash
    fi

    log "Checking installed agent CLIs..."
    for tool in codex opencode qwen kilo cline crush aider claude; do
      if command -v "$tool" >/dev/null 2>&1; then
        printf '%-10s %s\n' "$tool" "INSTALLED ($("$tool" --version 2>/dev/null | head -1 || true))"
      fi
    done
    ;;

  # ----------------------------------------------------------------------------
  # SUBCOMMAND: GUI (Headless computer-use control)
  # ----------------------------------------------------------------------------
  gui)
    export DISPLAY="${DISPLAY:-:0}"
    export XAUTHORITY="${XAUTHORITY:-/root/.Xauthority}"
    cmd="${1:-status}"
    shift || true
    case "$cmd" in
      status)
        echo "DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY"
        command -v xdotool >/dev/null 2>&1 && xdotool getactivewindow getwindowname || true
        ;;
      screenshot)
        file="${1:-/tmp/screen.png}"
        command -v import >/dev/null 2>&1 && import -display "$DISPLAY" -window root "$file" && echo "Saved: $file"
        ;;
      move)
        command -v xdotool >/dev/null 2>&1 && xdotool mousemove --sync "$1" "$2"
        ;;
      click)
        command -v xdotool >/dev/null 2>&1 && xdotool click "${1:-1}"
        ;;
      type)
        command -v xdotool >/dev/null 2>&1 && xdotool type --clearmodifiers --delay 20 -- "$*"
        ;;
      *)
        echo "Usage: $0 gui [status|screenshot <file>|move X Y|click [btn]|type TEXT]" >&2
        ;;
    esac
    ;;

  status|help|*)
    echo "NEXUS Linux Unified Engine"
    echo "Usage: $0 {runtime|bootstrap [core|full]|gui <cmd>|status}"
    ;;
esac
