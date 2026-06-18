#!/usr/bin/env python3
"""Build a lightweight file manifest for a staged batch.

The script is intentionally local and resumable. It does not read Google Drive
APIs directly; feed it a small staged folder in Codespaces or a controlled local
copy. Output is JSON Lines so large manifests can be streamed later.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Iterable


def iter_files(root: Path) -> Iterable[Path]:
    for path in sorted(root.rglob("*")):
        if path.is_file():
            yield path


def sha256_file(path: Path, block_size: int = 1024 * 1024) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        while True:
            block = fh.read(block_size)
            if not block:
                break
            h.update(block)
    return h.hexdigest()


def count_lines(path: Path) -> int | None:
    if path.suffix.lower() not in {".txt", ".md", ".csv", ".json", ".jsonl"}:
        return None
    try:
        with path.open("r", encoding="utf-8", errors="replace") as fh:
            return sum(1 for _ in fh)
    except OSError:
        return None


def build_record(root: Path, path: Path) -> dict:
    stat = path.stat()
    rel = path.relative_to(root).as_posix()
    return {
        "path": rel,
        "name": path.name,
        "suffix": path.suffix.lower(),
        "size_bytes": stat.st_size,
        "sha256": sha256_file(path),
        "line_count": count_lines(path),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path, help="Input folder to scan")
    parser.add_argument("--output", required=True, type=Path, help="Output JSONL manifest")
    args = parser.parse_args()

    root = args.input.resolve()
    if not root.exists() or not root.is_dir():
        raise SystemExit(f"Input folder not found or not a directory: {root}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    total = 0
    with args.output.open("w", encoding="utf-8") as out:
        for path in iter_files(root):
            rec = build_record(root, path)
            total += rec["size_bytes"]
            count += 1
            out.write(json.dumps(rec, ensure_ascii=False, sort_keys=True) + "\n")

    print(json.dumps({"files": count, "bytes": total, "output": str(args.output)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
