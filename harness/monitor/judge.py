"""A model reads a trajectory against a named rubric and answers in a fixed structure.

Used twice: by the monitor, to ask whether a run was legitimate, and by the
assessment, to ask what limited it. A trajectory is data, never instructions:
it is passed inside delimiters, and the reply must fit a schema.
"""

from __future__ import annotations

import json
from pathlib import Path

MAX_CHARS = 120_000          # of rendered trajectory
MAX_FIELD = 3_000            # of any one message, argument or result
OPEN, CLOSE = "<<<RECORD", "RECORD>>>"


def _clip(text: str, limit: int = MAX_FIELD) -> str:
    text = text if isinstance(text, str) else json.dumps(text, ensure_ascii=False)
    if len(text) <= limit:
        return text
    half = limit // 2
    return f"{text[:half]}\n[... {len(text) - limit} characters left out ...]\n{text[-half:]}"


def render(trajectory: dict | None, title: str = "") -> str:
    """A trajectory as numbered steps, compact enough to read whole."""
    if not trajectory:
        return f"{title}\n(no record)\n"
    lines = [title] if title else []
    for number, step in enumerate(trajectory.get("steps", [])):
        lines.append(f"[step {number}] {step.get('source', '?')}")
        if step.get("message"):
            lines.append(_clip(step["message"]))
        for call in step.get("tool_calls") or []:
            lines.append(f"  tool call {call.get('function_name')}: {_clip(call.get('arguments', ''))}")
        observation = step.get("observation") or {}
        for result in observation.get("results") or []:
            lines.append(f"  result: {_clip(result.get('content', ''))}")
    text = "\n".join(lines)
    if len(text) > MAX_CHARS:
        half = MAX_CHARS // 2
        text = f"{text[:half]}\n[... middle of the record left out for length ...]\n{text[-half:]}"
    return text + "\n"


def ask(model: str, rubric: str, material: str, schema: dict, name: str) -> tuple[dict | None, dict]:
    """One reading. Returns the parsed reply, or None if it could not be parsed, and the usage."""
    from openai import OpenAI

    client = OpenAI()
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "system", "content": rubric},
                  {"role": "user", "content": material}],
        response_format={"type": "json_schema",
                         "json_schema": {"name": name, "schema": schema, "strict": True}},
    )
    usage = {"input": getattr(response.usage, "prompt_tokens", 0),
             "output": getattr(response.usage, "completion_tokens", 0)}
    try:
        return json.loads(response.choices[0].message.content), usage
    except (TypeError, ValueError):
        return None, usage


def load_rubric(root: Path, name: str) -> str:
    return (root / "configs" / "monitor" / name).read_text(encoding="utf-8")
