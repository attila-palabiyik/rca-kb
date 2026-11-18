"""Turns one run into a Harbor task directory.

Harbor is known only here and in executor.py. A task directory holds what the
agent's container is built from, what the grading container is built from,
and the instructions for each turn.
"""

from __future__ import annotations

import json
import re
import shutil
from dataclasses import dataclass, field
from pathlib import Path

from harness.config.load import Setup
from harness.dataset.loader import Task
from harness.grader import registry

WORKDIR = "/app"
SOLVE, UPDATE = "solve", "update"


@dataclass
class Materialised:
    task_dir: Path
    steps: list[str]
    mounts: list[dict] = field(default_factory=list)
    agent_config: dict = field(default_factory=dict)


def harbor_name(task: Task, setup: Setup) -> str:
    """Unique per task and Setup, so two conditions never share a built image."""
    slug = re.sub(r"[^a-z0-9]+", "-", task.id.lower()).strip("-")
    return f"rcakb/{slug}-{setup.hash[:8]}"


def _write(path: Path, text: str, executable: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")
    if executable:
        path.chmod(0o755)


def _environment(task: Task, setup: Setup, dest: Path) -> None:
    env = dest / "environment"
    shutil.copytree(task.workspace, env / "workspace")
    lines = [f"FROM {setup.image}", f"WORKDIR {WORKDIR}", f"COPY workspace/ {WORKDIR}/"]
    for index, entry in enumerate(setup.files):
        source = Path(entry["source"])
        staged = env / "files" / str(index) / source.name
        staged.parent.mkdir(parents=True, exist_ok=True)
        if source.is_dir():
            shutil.copytree(source, staged)
            lines.append(f"COPY files/{index}/{source.name}/ {entry['target'].rstrip('/')}/")
        else:
            shutil.copy2(source, staged)
            lines.append(f"COPY files/{index}/{source.name} {entry['target']}")
    for target, inside_kb in setup.kb.get("links", {}).items():
        # A file inside the KB shown at a path the agent CLI reads on its own.
        parent = str(Path(target).parent).replace("\\", "/")
        kb_path = f"{setup.kb.get('path', '/kb').rstrip('/')}/{inside_kb}"
        lines.append(f"RUN mkdir -p {parent} && ln -sfn {kb_path} {target}")
    _write(env / "Dockerfile", "\n".join(lines) + "\n")


def _grading(task: Task, setup: Setup, tests: Path) -> None:
    """The grading container: the image, the grade program, the task's private data."""
    shutil.copytree(task.private, tests)
    shutil.copy2(registry.grade_program(task.grader), tests / "grade.py")
    _write(tests / "Dockerfile", f"FROM {setup.image}\nWORKDIR {WORKDIR}\nCOPY . /tests/\n")
    _write(tests / "test.sh",
           f"#!/bin/bash\npython3 /tests/grade.py {WORKDIR} /tests /logs/verifier\n", executable=True)


def _no_grading(setup: Setup, tests: Path) -> None:
    """The Update turn has nothing to grade; its step only has to report in."""
    _write(tests / "Dockerfile", f"FROM {setup.image}\nWORKDIR {WORKDIR}\nCOPY . /tests/\n")
    _write(tests / "test.sh", "#!/bin/bash\necho 1 > /logs/verifier/reward.txt\n", executable=True)


def _solution(task: Task, solution: Path) -> None:
    """What the known-good agent installs: the grader's known-good Submission."""
    script = ["#!/bin/bash", "set -e"]
    for name, content in registry.get(task.grader).known_good(task).items():
        script += [f"cat > {WORKDIR}/{name} <<'HARNESS_KNOWN_GOOD'",
                   content.decode("utf-8").rstrip("\n"), "HARNESS_KNOWN_GOOD"]
    _write(solution / "solve.sh", "\n".join(script) + "\n", executable=True)


def _task_toml(task: Task, setup: Setup, steps: list[str]) -> str:
    def quoted(items) -> str:
        return "[" + ", ".join(json.dumps(i) for i in items) + "]"

    artifacts = [f"{WORKDIR}/{name}" for name in registry.get(task.grader).submission_files(task)]
    network = setup.network
    out = [
        'schema_version = "1.4"',
        f"artifacts = {quoted(artifacts)}",
        "",
        "[task]",
        f"name = {json.dumps(harbor_name(task, setup))}",
        'version = "1.0.0"',
        f"description = {json.dumps(task.id)}",
        "authors = []",
        "keywords = []",
    ]
    if len(steps) > 1:
        limits = {SOLVE: (setup.limits["solve"], setup.limits["grade"]),
                  UPDATE: (setup.limits["update"], 60)}
        for step in steps:
            agent_limit, verifier_limit = limits[step]
            out += ["", "[[steps]]", f"name = {json.dumps(step)}", "artifacts = []",
                    "[steps.agent]", f"timeout_sec = {float(agent_limit)}",
                    "[steps.verifier]", f"timeout_sec = {float(verifier_limit)}"]
    out += [
        "",
        "[metadata]",
        "",
        "[verifier]",
        f"timeout_sec = {float(setup.limits['grade'])}",
        'environment_mode = "separate"',
        "",
        "[agent]",
        f"timeout_sec = {float(setup.limits['solve'])}",
        "",
        "[environment]",
        f"network_mode = {json.dumps(network.get('mode', 'allowlist'))}",
    ]
    if network.get("mode", "allowlist") == "allowlist":
        out.append(f"allowed_hosts = {quoted(network.get('hosts', []))}")
    out += ["build_timeout_sec = 900.0", 'os = "linux"']
    for server in setup.mcp_servers:
        out += ["", "[[environment.mcp_servers]]", f"name = {json.dumps(server['name'])}",
                'transport = "stdio"', f"command = {json.dumps(server['command'])}",
                f"args = {quoted(server.get('args', []))}"]
    out += ["", "[solution.env]", ""]
    return "\n".join(out)


def agent_config(setup: Setup) -> dict:
    """The agent's own config: the Setup's settings plus its memory switches."""
    config = json.loads(json.dumps(setup.settings))
    config.pop("web_search", None)                 # passed as its own option
    if setup.agent.get("name") == "codex":
        features = config.setdefault("features", {})
        features["memories"] = setup.agent_memory.get("builtin") == "on"
    return config


def materialise(task: Task, setup: Setup, dest: Path, *, kb_copy: Path | None = None,
                with_update: bool = False) -> Materialised:
    """Write the Harbor task for one run of `task` under `setup`."""
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True)
    steps = [SOLVE, UPDATE] if with_update else [SOLVE]
    _environment(task, setup, dest)
    first_turn = setup.first_turn(task.instructions)

    if with_update:
        _write(dest / "steps" / SOLVE / "instruction.md", first_turn)
        _grading(task, setup, dest / "steps" / SOLVE / "tests")
        _solution(task, dest / "steps" / SOLVE / "solution")
        _write(dest / "steps" / UPDATE / "instruction.md", setup.update_prompt.strip() + "\n")
        _no_grading(setup, dest / "steps" / UPDATE / "tests")
        _write(dest / "steps" / UPDATE / "solution" / "solve.sh", "#!/bin/bash\n", executable=True)
    else:
        _write(dest / "instruction.md", first_turn)
        _grading(task, setup, dest / "tests")
        _solution(task, dest / "solution")
    _write(dest / "task.toml", _task_toml(task, setup, steps))

    mounts = []
    if kb_copy is not None:
        paths = setup.kb.get("paths")
        if paths:
            for subdir, target in paths.items():
                (kb_copy / subdir).mkdir(parents=True, exist_ok=True)
                mounts.append({"type": "bind", "source": str(kb_copy / subdir), "target": target})
        else:
            mounts.append({"type": "bind", "source": str(kb_copy),
                           "target": setup.kb.get("path", "/kb")})
    return Materialised(dest, steps, mounts, agent_config(setup))
