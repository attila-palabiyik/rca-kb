#!/usr/bin/env python3
"""Similarity search over a folder of text files. Runs locally, with no network.

    kbsearch index [DIR]              embed every text file under DIR
    kbsearch query "TEXT" [DIR] [-k N]  print the N files closest in meaning to TEXT

DIR defaults to /kb. The index is kept inside DIR, in .kbsearch/index.json, so
it travels with the folder. `query` first brings the index up to date.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
from pathlib import Path

MODEL = "BAAI/bge-small-en-v1.5"
MODEL_DIR = os.environ.get("KBSEARCH_MODELS", "/opt/kbsearch/models")
SUFFIXES = {".md", ".txt", ".sv", ".v", ".json", ".jsonl", ".toml", ".yaml", ".yml", ".sh", ".py"}
MAX_CHARS = 6000
INDEX_DIR = ".kbsearch"


def _embed(texts: list[str]) -> list[list[float]]:
    from fastembed import TextEmbedding

    model = TextEmbedding(MODEL, cache_dir=MODEL_DIR)
    return [[float(x) for x in vector] for vector in model.embed(texts)]


def _files(root: Path) -> list[Path]:
    return sorted(
        p for p in root.rglob("*")
        if p.is_file() and p.suffix.lower() in SUFFIXES and INDEX_DIR not in p.parts
    )


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")[:MAX_CHARS]


def update_index(root: Path) -> dict:
    index_path = root / INDEX_DIR / "index.json"
    index = {"model": MODEL, "files": {}}
    if index_path.is_file():
        loaded = json.loads(index_path.read_text())
        if loaded.get("model") == MODEL:
            index = loaded
    current = {p.relative_to(root).as_posix(): p for p in _files(root)}
    for gone in set(index["files"]) - set(current):
        del index["files"][gone]
    stale = [
        rel for rel, p in current.items()
        if index["files"].get(rel, {}).get("stamp") != [p.stat().st_mtime_ns, p.stat().st_size]
    ]
    if stale:
        vectors = _embed([_read(current[rel]) or rel for rel in stale])
        for rel, vector in zip(stale, vectors):
            stat = current[rel].stat()
            index["files"][rel] = {"stamp": [stat.st_mtime_ns, stat.st_size], "vector": vector}
        index_path.parent.mkdir(parents=True, exist_ok=True)
        index_path.write_text(json.dumps(index))
    return index


def _cosine(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    norm = math.sqrt(sum(x * x for x in a)) * math.sqrt(sum(y * y for y in b))
    return dot / norm if norm else 0.0


def _first_line(path: Path) -> str:
    for line in _read(path).splitlines():
        if line.strip():
            return line.strip()[:100]
    return ""


def main() -> int:
    parser = argparse.ArgumentParser(prog="kbsearch", description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    index_cmd = sub.add_parser("index", help="embed every text file under DIR")
    index_cmd.add_argument("dir", nargs="?", default="/kb")
    query_cmd = sub.add_parser("query", help="print the files closest in meaning to TEXT")
    query_cmd.add_argument("text")
    query_cmd.add_argument("dir", nargs="?", default="/kb")
    query_cmd.add_argument("-k", type=int, default=5)
    args = parser.parse_args()

    root = Path(args.dir)
    if not root.is_dir():
        print(f"kbsearch: {root} is not a directory", file=sys.stderr)
        return 2
    index = update_index(root)
    if args.command == "index":
        print(f"indexed {len(index['files'])} files under {root}")
        return 0
    if not index["files"]:
        print("no files to search")
        return 0
    (query_vector,) = _embed([args.text])
    ranked = sorted(
        ((_cosine(query_vector, entry["vector"]), rel) for rel, entry in index["files"].items()),
        reverse=True,
    )
    for score, rel in ranked[: args.k]:
        print(f"{score:.3f}  {root / rel}  {_first_line(root / rel)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
