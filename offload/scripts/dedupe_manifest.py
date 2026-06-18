#!/usr/bin/env python3
"""Report duplicate files from a JSONL manifest produced by manifest.py."""

from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path


def load_manifest(path: Path) -> list[dict]:
    rows: list[dict] = []
    with path.open("r", encoding="utf-8") as fh:
        for line_no, line in enumerate(fh, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError as exc:
                raise SystemExit(f"Invalid JSON at {path}:{line_no}: {exc}") from exc
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    rows = load_manifest(args.manifest)
    by_hash: dict[str, list[dict]] = collections.defaultdict(list)
    by_name_size: dict[tuple[str, int], list[dict]] = collections.defaultdict(list)
    for row in rows:
        by_hash[row.get("sha256", "")].append(row)
        by_name_size[(row.get("name", ""), int(row.get("size_bytes") or 0))].append(row)

    exact = {k: v for k, v in by_hash.items() if k and len(v) > 1}
    probable = {k: v for k, v in by_name_size.items() if k[0] and len(v) > 1}

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as out:
        out.write("# Duplicate report\n\n")
        out.write(f"Total files reviewed: {len(rows)}\n\n")
        out.write(f"Exact duplicate groups by sha256: {len(exact)}\n")
        out.write(f"Probable duplicate groups by name+size: {len(probable)}\n\n")

        out.write("## Exact duplicates\n\n")
        for sha, items in sorted(exact.items()):
            out.write(f"### {sha}\n")
            for item in sorted(items, key=lambda r: r.get("path", "")):
                out.write(f"- `{item.get('path')}` ({item.get('size_bytes')} bytes)\n")
            out.write("\n")

        out.write("## Probable duplicates by name and size\n\n")
        for (name, size), items in sorted(probable.items()):
            out.write(f"### {name} ({size} bytes)\n")
            for item in sorted(items, key=lambda r: r.get("path", "")):
                out.write(f"- `{item.get('path')}` sha256={item.get('sha256')}\n")
            out.write("\n")

    print(json.dumps({"files": len(rows), "exact_groups": len(exact), "probable_groups": len(probable), "output": str(args.output)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
