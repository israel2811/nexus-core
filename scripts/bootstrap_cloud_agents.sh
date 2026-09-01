#!/usr/bin/env bash
set -euo pipefail
PROFILE="${1:-core}"

export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin"

echo "[NEXUS] cloud agent profile=$PROFILE"
echo "[NEXUS] no credentials are read or written by this script"

if command -v npm >/dev/null 2>&1; then
  npm install -g @openai/codex opencode-ai @qwen-code/qwen-code@latest
else
  echo "[NEXUS] npm missing; core Node agents skipped" >&2
fi

if [[ "$PROFILE" == "full" ]]; then
  if command -v npm >/dev/null 2>&1; then
    npm install -g @kilocode/cli cline @charmland/crush
  fi
  python3 -m pip install --user --upgrade aider-chat || true
  if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
  fi
fi

echo "[NEXUS] versions"
for x in codex opencode qwen kilo cline crush aider claude; do
  if command -v "$x" >/dev/null 2>&1; then
    printf '%-10s ' "$x"
    "$x" --version 2>/dev/null | head -1 || true
  else
    printf '%-10s %s\n' "$x" 'not-installed'
  fi
done

echo "[NEXUS] authenticate interactively inside each CLI when needed; do not paste secrets into scripts."