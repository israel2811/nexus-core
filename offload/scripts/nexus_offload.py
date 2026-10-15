#!/usr/bin/env python3
"""NEXUS Unified Offload Processor.

Consolidates batch manifest creation, deduplication detection, and document
chunking for Google Docs into a single canonical Python utility.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import re
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


def cmd_manifest(args: argparse.Namespace) -> int:
    root = args.input.resolve()
    if not root.exists() or not root.is_dir():
        raise SystemExit(f"Input folder not found or not a directory: {root}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    total = 0
    with args.output.open("w", encoding="utf-8") as out:
        for path in iter_files(root):
            stat = path.stat()
            rec = {
                "path": path.relative_to(root).as_posix(),
                "name": path.name,
                "suffix": path.suffix.lower(),
                "size_bytes": stat.st_size,
                "sha256": sha256_file(path),
                "line_count": count_lines(path),
            }
            total += rec["size_bytes"]
            count += 1
            out.write(json.dumps(rec, ensure_ascii=False, sort_keys=True) + "\n")

    print(json.dumps({"files": count, "bytes": total, "output": str(args.output)}, ensure_ascii=False))
    return 0


def cmd_dedupe(args: argparse.Namespace) -> int:
    rows = []
    with args.manifest.open("r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                rows.append(json.loads(line))

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
        out.write(f"Exact duplicate groups: {len(exact)}\n")
        out.write(f"Probable duplicate groups: {len(probable)}\n\n")
        for sha, items in sorted(exact.items()):
            out.write(f"### SHA: {sha}\n")
            for item in sorted(items, key=lambda r: r.get("path", "")):
                out.write(f"- `{item.get('path')}` ({item.get('size_bytes')} bytes)\n")
            out.write("\n")

    print(json.dumps({"files": len(rows), "exact_groups": len(exact), "output": str(args.output)}, ensure_ascii=False))
    return 0


def cmd_split(args: argparse.Namespace) -> int:
    source = args.input.resolve()
    if source.is_file():
        files = [source]
        root = source.parent
    elif source.is_dir():
        files = [p for p in sorted(source.rglob("*")) if p.is_file() and p.suffix.lower() in {".txt", ".md"}]
        root = source
    else:
        raise SystemExit(f"Input not found: {source}")

    args.output.mkdir(parents=True, exist_ok=True)
    index_rows = []
    for path in files:
        text = path.read_text(encoding="utf-8", errors="replace")
        chunks = []
        start = 0
        while start < len(text):
            end = min(start + args.max_chars, len(text))
            chunk = text[start:end].strip()
            if chunk:
                chunks.append(chunk)
            start = end
        base = re.sub(r"[^A-Za-z0-9._-]+", "_", path.stem).strip("._-") or "chunk"
        rel = path.relative_to(root).as_posix() if path.is_relative_to(root) else path.name
        for i, chunk in enumerate(chunks, start=1):
            out_name = f"{base}_parte{i:03d}.md"
            (args.output / out_name).write_text(f"# {path.name} ({i}/{len(chunks)})\n\nSource: `{rel}`\n\n{chunk}\n", encoding="utf-8")
            index_rows.append({"source": rel, "part": i, "parts": len(chunks), "output": out_name, "chars": len(chunk)})

    index_path = args.output / "00_INDEX_CHUNKS.jsonl"
    with index_path.open("w", encoding="utf-8") as fh:
        for row in index_rows:
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")

    print(json.dumps({"files": len(files), "chunks": len(index_rows), "index": str(index_path)}, ensure_ascii=False))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="NEXUS Unified Offload Processor")
    sub = parser.add_subparsers(dest="command", required=True)

    p_man = sub.add_parser("manifest", help="Generate JSONL file manifest")
    p_man.add_argument("--input", required=True, type=Path)
    p_man.add_argument("--output", required=True, type=Path)

    p_dup = sub.add_parser("dedupe", help="Detect duplicates from manifest")
    p_dup.add_argument("--manifest", required=True, type=Path)
    p_dup.add_argument("--output", required=True, type=Path)

    p_spl = sub.add_parser("split", help="Split text into chunked markdown")
    p_spl.add_argument("--input", required=True, type=Path)
    p_spl.add_argument("--output", required=True, type=Path)
    p_spl.add_argument("--max-chars", type=int, default=180_000)

    args = parser.parse_args()
    if args.command == "manifest":
        return cmd_manifest(args)
    elif args.command == "dedupe":
        return cmd_dedupe(args)
    elif args.command == "split":
        return cmd_split(args)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
