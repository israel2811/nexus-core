#!/bin/bash
set -euo pipefail
echo "[NEXUS] bootstrap start"

python3 -m pip install --upgrade pip >/dev/null 2>&1 || true

if [ -f "requirements.txt" ]; then
  pip install -r requirements.txt >/dev/null || true
else
  pip install requests huggingface_hub supabase >/dev/null || true
fi

npm install -g pm2 >/dev/null 2>&1 || true

if [ -f ".env" ]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

python3 scripts/auto_restore.py --dry-run >/dev/null 2>&1 || true
chmod +x scripts/codespace_runtime.sh 2>/dev/null || true
bash scripts/codespace_runtime.sh || true

echo "[NEXUS] bootstrap complete"
