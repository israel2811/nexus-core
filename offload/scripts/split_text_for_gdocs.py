#!/usr/bin/env python3
"""Split text/markdown files into bounded chunks for Google Docs ingestion."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

TEXT_SUFFIXES = {".txt", ".md", ".markdown"}


def safe_stem(path: Path) -> str:
    stem = re.sub(r"[^A-Za-z0-9._-]+", "_", path.stem).strip("._-")
    return stem or "chunk"


def split_text(text: str, max_chars: int) -> list[str]:
    if len(text) <= max_chars:
        return [text]
    chunks: list[str] = []
    start = 0
    while start < len(text):
        end = min(start + max_chars, len(text))
        if end < len(text):
            window = text[start:end]
            candidates = [window.rfind("\n\n"), window.rfind("\n"), window.rfind(". ")]
            cut = max(candidates)
            if cut > max_chars * 0.55:
                end = start + cut + (2 if window[cut:cut + 2] == ". " else 0)
        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)
        start = end
    return chunks


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path, help="Input file or folder")
    parser.add_argument("--output", required=True, type=Path, help="Output folder")
    parser.add_argument("--max-chars", type=int, default=180_000)
    args = parser.parse_args()

    source = args.input.resolve()
    if source.is_file():
        files = [source]
        root = source.parent
    elif source.is_dir():
        files = [p for p in sorted(source.rglob("*")) if p.is_file() and p.suffix.lower() in TEXT_SUFFIXES]
        root = source
    else:
        raise SystemExit(f"Input not found: {source}")

    args.output.mkdir(parents=True, exist_ok=True)
    index_rows = []
    for path in files:
        text = path.read_text(encoding="utf-8", errors="replace")
        parts = split_text(text, args.max_chars)
        base = safe_stem(path)
        rel = path.relative_to(root).as_posix() if path.is_relative_to(root) else path.name
        for i, chunk in enumerate(parts, start=1):
            out_name = f"{base}_parte{i:03d}.md"
            out_path = args.output / out_name
            header = f"# {path.name} - parte {i:03d} de {len(parts):03d}\n\nSource: `{rel}`\n\n"
            out_path.write_text(header + chunk + "\n", encoding="utf-8")
            index_rows.append({"source": rel, "part": i, "parts": len(parts), "output": out_name, "chars": len(chunk)})

    index_path = args.output / "00_INDEX_CHUNKS.jsonl"
    with index_path.open("w", encoding="utf-8") as fh:
        for row in index_rows:
            fh.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")

    print(json.dumps({"source_files": len(files), "chunks": len(index_rows), "index": str(index_path)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
