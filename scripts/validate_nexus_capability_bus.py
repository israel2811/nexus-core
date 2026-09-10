from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "configs" / "nexus-capabilities.public.json"
REQUIRED = ROOT / "NEXUS_MULTI_AI_BRIEF.md"
AGENTS = ROOT / "AGENTS.md"

SECRET_PATTERNS = [
    re.compile(r"gh[pousr]_[A-Za-z0-9_]{20,}"),
    re.compile(r"sk-[A-Za-z0-9_-]{20,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
]

errors: list[str] = []
for path in (REGISTRY, REQUIRED, AGENTS):
    if not path.exists():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")

if REGISTRY.exists():
    data = json.loads(REGISTRY.read_text(encoding="utf-8"))
    if data.get("schema_version") != "1.0":
        errors.append("unexpected capability schema_version")
    if data.get("private_context", {}).get("contains_credentials") is not False:
        errors.append("private_context.contains_credentials must be false")

for path in (REGISTRY, REQUIRED, AGENTS):
    if path.exists():
        text = path.read_text(encoding="utf-8", errors="replace")
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                errors.append(f"possible secret found in {path.relative_to(ROOT)}")

if errors:
    print("NEXUS capability-bus validation FAILED")
    print("\n".join(f"- {e}" for e in errors))
    sys.exit(1)

print("NEXUS capability-bus validation OK")