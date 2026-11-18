"""KB state, directory backend: one directory, identified by its contents.

The harness asks four things of any KB state and nothing else: identify a
state, snapshot it, restore it, and freeze it. Here a snapshot is a copy, the
ID is a hash of the contents, and a frozen KB is a private copy that is thrown
away after the run. The contents are never interpreted.
"""

from __future__ import annotations

import hashlib
import shutil
from pathlib import Path


def identify(state: Path | None) -> str:
    """A stable ID for a state: a hash of every file's path and bytes."""
    digest = hashlib.sha256()
    if state is not None and state.is_dir():
        for path in sorted(p for p in state.rglob("*") if p.is_file()):
            digest.update(path.relative_to(state).as_posix().encode())
            digest.update(b"\0")
            digest.update(path.read_bytes())
            digest.update(b"\0")
    return digest.hexdigest()[:16]


def snapshot(state: Path | None, snapshots: Path) -> str:
    """Capture a state under `snapshots/<id>/` and return the ID."""
    state_id = identify(state)
    target = snapshots / state_id
    if not target.exists():
        if state is not None and state.is_dir():
            shutil.copytree(state, target, symlinks=True)
        else:
            target.mkdir(parents=True)
    return state_id


def restore(snapshots: Path, state_id: str, dest: Path) -> Path:
    """A fresh working copy of a captured state."""
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(snapshots / state_id, dest, symlinks=True)
    return dest
