"""Draws the diagrams of the slides' Harness, Baseline, Knowledge bases and Results sections into docs/figures/.

    python scripts/make_slide_figures.py

Each is drawn at 1120 units wide, the slide's content width, so a unit is a
pixel on the slide. The monitor figure counts runs and reviews from runs/.
"""

from __future__ import annotations

import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "figures"
INK, SOFT, FAINT, RULE, WASH = "#0d1117", "#5b6068", "#8f949b", "#dbdcdd", "#f4f4f4"
KB, KB_TEXT, KB_WASH, KB_PALE = "#fd6420", "#c4490f", "#ffd9bd", "#fff4ec"
SANS = "'Figtree', 'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
MONO = "'JetBrains Mono', Consolas, monospace"


class Svg:
    def __init__(self, width: int, height: int) -> None:
        self.width, self.height, self.parts = width, height, []

    def text(self, x, y, value, size=15, weight=400, fill=INK, anchor="start", mono=False) -> None:
        family = f' font-family="{MONO}"' if mono else ""
        self.parts.append(f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{fill}" '
                          f'text-anchor="{anchor}"{family}>{html.escape(value)}</text>')

    def rect(self, x, y, w, h, fill="none", stroke=None, width=1.25, radius=0, dash=None) -> None:
        extra = f' stroke="{stroke}" stroke-width="{width}"' if stroke else ""
        extra += f' stroke-dasharray="{dash}"' if dash else ""
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}"{extra}/>')

    def line(self, points, stroke=SOFT, width=1.25, arrow=True, both=False, dash=None) -> None:
        name = {SOFT: "soft", INK: "ink", KB: "kb"}.get(stroke, "soft")
        d = "M" + " L".join(f"{x} {y}" for x, y in points)
        extra = f' marker-end="url(#head-{name})"' if arrow else ""
        extra += f' marker-start="url(#head-{name})"' if both else ""
        extra += f' stroke-dasharray="{dash}"' if dash else ""
        self.parts.append(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{width}"{extra}/>')

    def node(self, x, y, w, h, title, lines=(), kind="core", mono_lines=False) -> None:
        stroke, fill, width = {"core": (INK, "#fff", 1.25), "main": (INK, "#fff", 2), "outside": (FAINT, "#fff", 1),
                               "kb": (KB, KB_PALE, 1.25)}[kind]
        self.rect(x, y, w, h, fill=fill, stroke=stroke, width=width, radius=6)
        self.text(x + 13, y + 25, title, 16, 600, KB_TEXT if kind == "kb" else INK)
        for index, value in enumerate(lines):
            self.text(x + 13, y + 45 + 17 * index, value, 12.5 if mono_lines else 13.5, 400, SOFT, mono=mono_lines)

    def save(self, name: str) -> None:
        heads = "".join(
            f'<marker id="head-{name}" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="7" markerHeight="7" '
            f'orient="auto-start-reverse"><path d="M0.5,0.8 L7,4 L0.5,7.2" fill="none" stroke="{colour}" '
            f'stroke-width="1.3"/></marker>' for name, colour in (("soft", SOFT), ("ink", INK), ("kb", KB)))
        body = "\n  ".join(self.parts)
        (OUT / name).write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.width} {self.height}" '
            f'font-family="{SANS}" fill="{INK}">\n  <defs>{heads}</defs>\n  {body}\n</svg>\n',
            encoding="utf-8", newline="\n")


def experiment() -> None:
    """Sets A and B as task squares: three runs each with no KB; with a KB, it grows over A and is frozen for B."""
    s = Svg(1120, 330)
    a0, b0, pitch, size, freeze = 190, 682, 9.8, 8, 657
    s.text(a0, 16, "Set A", 17, 600)
    s.text(a0 + 54, 16, "45 tasks in 17 modules", 15, 400, SOFT)
    s.text(b0, 16, "Set B", 17, 600)
    s.text(b0 + 54, 16, "41 tasks in 15 other modules", 15, 400, SOFT)

    s.text(0, 62, "No KB", 17, 600)
    s.text(0, 82, "three runs per task", 14, 400, SOFT)
    for start, count in ((a0, 45), (b0, 41)):
        for i in range(count):
            for row in range(3):
                s.rect(round(start + i * pitch, 1), 46 + row * 10, size, size, fill="#c6c8cc")

    s.line([(b0 + 200, 150), (b0 + 200, 86)], stroke=SOFT, both=True)
    s.text(b0 + 212, 123, "compared, task by task", 14, 400, SOFT)

    s.text(0, 176, "With a KB", 17, 600)
    s.text(0, 196, "one of 13 approaches,", 14, 400, SOFT)
    s.text(0, 214, "one run per task", 14, 400, SOFT)
    base, tall = 292, 96
    for i in range(45):
        x = round(a0 + i * pitch, 1)
        height = round(6 + i * (tall - 6) / 44, 1)
        s.rect(x, 160, size, size, fill=INK)
        s.rect(x, round(base - height, 1), size, height, fill=KB)
    for i in range(41):
        x = round(b0 + i * pitch, 1)
        s.rect(x, 160, size, size, fill=INK)
        s.rect(x, base - tall, size, tall, fill=KB)
    s.text(a0 + 2, 218, "the KB grows", 14, 600, KB_TEXT)
    s.line([(freeze, 150), (freeze, 298)], stroke=INK, width=1.5, arrow=False)
    s.text(freeze, 140, "frozen", 14, 600, INK, "middle")
    s.text(a0, 318, "after each task the agent sees the fix and updates its KB", 14, 400, SOFT)
    s.text(b0, 318, "every task gets a copy of the same KB", 14, 400, SOFT)
    s.save("experiment.svg")


def architecture() -> None:
    """Components and flows: the runner at the centre, with the benchmark, the KB approaches, the containers,
    the reviewer and the report outside the harness's edge. Dashed: what can be swapped for another. The two
    ports sit on the harness's edge, where what is swapped plugs in."""
    s = Svg(1120, 476)
    s.rect(201, 14, 749, 314, fill="#f8f8f8", stroke=RULE, width=1, radius=12)
    s.text(218, 36, "Harness", 13, 600, FAINT)

    # Outside, left
    s.rect(0, 54, 140, 46, fill="#fff", stroke=SOFT, width=1.25, radius=6, dash="5 4")
    s.text(13, 82, "ChipBench", 16, 600)
    s.rect(0, 122, 140, 46, fill=KB_PALE, stroke=KB, width=1.25, radius=6)
    s.text(13, 150, "KB approaches", 16, 600, KB_TEXT)
    s.rect(0, 188, 140, 46, fill="#fff", stroke=FAINT, width=1, radius=6)
    s.text(13, 216, "Experiment file", 16, 600)
    # Inside
    s.node(262, 48, 140, 58, "Dataset", ("tasks, split",))
    s.node(262, 122, 140, 112, "Configuration", ("base setup", "+ one overlay"))
    s.node(262, 252, 140, 58, "KB states", ("snapshots, by hash",), "kb")
    s.node(436, 48, 150, 186, "Runner", ("chains on set A", "batches on set B", "limits, retries"), "main")
    s.node(620, 48, 135, 66, "Run records", ("one per run",))
    s.node(620, 170, 135, 64, "Grader", ("pass or fail",))
    s.node(795, 48, 130, 66, "Monitor", ("judge + patterns",))
    s.node(795, 170, 130, 64, "Reporting", ("paired, intervals",))
    # Outside, right and below
    s.node(990, 48, 130, 66, "Reviewer", ("clears or voids",), "outside")
    s.node(990, 170, 130, 64, "Report", ("tables, figures",), "outside")
    s.rect(410, 352, 391, 116, fill="#fff", stroke=SOFT, width=1.25, radius=8, dash="5 4")
    s.text(425, 373, "Harbor", 13, 600, FAINT)
    s.node(425, 384, 172, 72, "Agent container", ("codex · iverilog", "/app  /kb"), "outside", mono_lines=True)
    s.node(614, 384, 172, 72, "Grader container", ("testbench", "reference"), "outside", mono_lines=True)

    # Flows
    s.line([(140, 77), (260, 77)])
    s.line([(140, 145), (260, 145)], stroke=KB)
    s.line([(140, 211), (260, 211)])
    s.line([(332, 106), (332, 120)])
    s.line([(402, 178), (434, 178)])
    s.line([(402, 270), (458, 270), (458, 236)], stroke=KB)
    s.line([(480, 234), (480, 294), (404, 294)], stroke=KB)
    s.text(410, 264, "copy", 11.5, 500, KB_TEXT, mono=True)
    s.text(410, 309, "snapshot", 11.5, 500, KB_TEXT, mono=True)
    s.line([(511, 236), (511, 382)], both=True)
    s.line([(586, 81), (618, 81)])
    s.line([(586, 190), (618, 190)])
    s.line([(620, 214), (588, 214)], stroke=KB)
    s.line([(700, 236), (700, 382)], both=True)
    s.line([(655, 170), (655, 116)])
    s.text(663, 148, "verdict", 11.5, 500, SOFT, mono=True)
    s.line([(755, 68), (793, 68)])
    s.line([(795, 94), (757, 94)])
    s.line([(735, 114), (735, 142), (860, 142), (860, 168)])
    s.line([(925, 68), (988, 68)])
    s.line([(990, 94), (927, 94)])
    s.text(957, 60, "flags", 11.5, 500, SOFT, "middle", mono=True)
    s.text(957, 110, "decision", 11.5, 500, SOFT, "middle", mono=True)
    s.line([(925, 202), (988, 202)])

    # Ports on the harness's edge, over the flows that pass through them
    s.rect(164, 66, 74, 22, fill="#fff", stroke=INK, width=1, radius=11)
    s.text(201, 81, "converter", 11, 500, INK, "middle", mono=True)
    s.rect(486, 317, 240, 22, fill="#fff", stroke=INK, width=1, radius=11)
    s.text(606, 332, "executor", 11, 500, INK, "middle", mono=True)
    s.save("architecture_slide.svg")


def run() -> None:
    """One run as lanes over time: the agent's container, the KB, and the grader's container."""
    s = Svg(1120, 372)
    for x, label, colour in ((160, "Prepare", SOFT), (270, "Solve", SOFT), (600, "Grade", SOFT),
                             (790, "Update", KB_TEXT), (1000, "Record", SOFT)):
        s.text(x, 14, label, 14, 600, colour)
    s.line([(160, 26), (1120, 26)], stroke=SOFT, width=1, arrow=False)

    s.text(0, 86, "Agent container", 16, 600)
    s.text(0, 106, "fresh for every run", 13.5, 400, SOFT)
    s.text(0, 198, "KB", 16, 600, KB_TEXT)
    s.text(0, 218, "snapshots, by hash", 13.5, 400, SOFT)
    s.text(0, 306, "Grader container", 16, 600)
    s.text(0, 326, "never seen by the agent", 13.5, 400, SOFT)

    s.rect(160, 52, 92, 36, fill="#fff", stroke=FAINT, width=1, radius=6)
    s.text(206, 75, "task", 13.5, 500, SOFT, "middle")
    s.rect(160, 100, 92, 36, fill="#fff", stroke=FAINT, width=1, radius=6)
    s.text(206, 123, "setup", 13.5, 500, SOFT, "middle")
    s.line([(252, 70), (268, 70)])
    s.line([(252, 118), (268, 118)])
    s.rect(270, 52, 290, 84, fill=WASH, stroke=INK, radius=6)
    s.text(286, 84, "Codex solves the task", 16, 600)
    s.text(286, 107, "edits the module, may write its own tests", 13, 400, SOFT)
    s.rect(790, 52, 180, 84, fill=KB_PALE, stroke=KB, radius=6)
    s.text(806, 84, "The session resumes", 16, 600)
    s.text(806, 107, "and updates the KB", 13, 400, SOFT)

    s.rect(160, 182, 92, 44, fill=KB_WASH, stroke=KB, radius=6)
    s.text(206, 209, "08f97f", 13, 500, INK, "middle", mono=True)
    s.rect(1000, 182, 92, 44, fill=KB_WASH, stroke=KB, radius=6)
    s.text(1046, 209, "54e89f", 13, 500, INK, "middle", mono=True)
    s.line([(252, 204), (310, 204), (310, 138)], stroke=KB)
    s.text(318, 176, "a private copy", 12.5, 500, KB_TEXT)
    s.line([(880, 136), (880, 204), (998, 204)], stroke=KB)
    s.text(888, 196, "next snapshot", 12.5, 500, KB_TEXT)

    s.rect(600, 272, 164, 84, fill=WASH, stroke=INK, radius=6)
    s.text(616, 304, "Testbench", 16, 600)
    s.text(616, 327, "against the reference", 13, 400, SOFT)
    s.rect(1000, 272, 120, 84, fill="#fff", stroke=INK, radius=6)
    s.text(1014, 304, "Run record", 16, 600)
    s.text(1014, 327, "verdict, tokens,", 13, 400, SOFT)
    s.text(1014, 344, "time, trajectory", 13, 400, SOFT)

    s.line([(540, 136), (540, 314), (598, 314)])
    s.text(548, 258, "answer", 12.5, 500, SOFT)
    s.line([(764, 296), (830, 296), (830, 138)], stroke=KB)
    s.text(838, 258, "verdict and the fix", 12.5, 500, KB_TEXT)
    s.line([(764, 336), (998, 336)])
    s.save("run_slide.svg")


def monitor() -> None:
    """Every run as a cell: no KB, with a KB, and flagged; then what the flags were."""
    baseline = len(list((ROOT / "runs" / "baseline").glob("*/*/*/record.json")))
    with_kb = len(list(ROOT.glob("runs/kb-*/*/*/*/record.json")))
    kinds = {"path": 0, "module": 0, "other": 0}
    for file in ROOT.glob("runs/kb-*/reviews.json"):
        for review in json.loads(file.read_text(encoding="utf-8")).values():
            note = review["note"]
            kind = ("module" if "KB's own entry" in note or "three earlier tasks" in note
                    else "path" if "reading, or declining to read, its KB" in note else "other")
            kinds[kind] += 1
    flagged = sum(kinds.values())
    total = baseline + with_kb

    s = Svg(1120, 436)
    rows, pitch, size = 16, 13, 9.6
    for i in range(total):
        colour = "#c6c8cc" if i < baseline else KB_WASH if i < total - flagged else INK
        s.rect(round((i // rows) * pitch, 1), (i % rows) * pitch, size, size, fill=colour)
    kb_x = round((baseline // rows + 1) * pitch)
    flag_x = round(((total - flagged) // rows) * pitch)
    s.text(0, 232, f"{baseline} runs with no KB", 14, 600)
    s.text(0, 250, "none flagged", 14, 400, SOFT)
    s.text(kb_x, 232, f"{with_kb:,} runs with a KB", 14, 600)
    s.text(1118, 232, f"{flagged} flagged", 14, 600, INK, "end")
    s.text(1118, 250, "all reviewed and cleared, none voided", 14, 400, SOFT, "end")

    s.text(0, 290, f"What the {flagged} flags were", 13.5, 500, SOFT)
    s.line([(0, 300), (840, 300)], stroke=INK, width=1, arrow=False)
    s.text(880, 290, "Testing the monitor itself", 13.5, 500, SOFT)
    s.line([(880, 300), (1120, 300)], stroke=INK, width=1, arrow=False)
    columns = [
        (0, str(kinds["path"]), "The KB is outside the workspace", ("The rules say to work only in /app;", "the KB sits at /kb.")),
        (290, str(kinds["module"]), "The fix was already in the KB", ("On set A, an earlier task of the same", "module had been shown its fix.")),
        (580, str(kinds["other"]), "Ordinary steps", ("Reading or editing the module itself.", "Each was read in full.")),
        (880, "20 of 20", "Planted violations caught", ("Violations written into clean runs", "to see whether it would notice.")),
    ]
    for x, count, title, lines in columns:
        s.text(x, 346, count, 42, 600)
        s.text(x, 376, title, 16, 600)
        for index, value in enumerate(lines):
            s.text(x, 398 + 19 * index, value, 13.5, 400, SOFT)
    s.save("monitor.svg")


def _baseline():
    """The baseline's runs, and each set's modules as lists of tasks, each a list of three verdicts."""
    import sys
    sys.path.insert(0, str(ROOT))
    from harness.report import metrics
    rows = [r for r in metrics.load([ROOT / "runs" / "baseline"], ROOT).rows if not r.pending]
    sets = {}
    for side in "AB":
        modules: dict[str, dict[str, list[bool]]] = {}
        for r in sorted((r for r in rows if r.side == side), key=lambda r: (r.task_id, r.repeat)):
            modules.setdefault(r.group, {}).setdefault(r.task_id, []).append(r.passed)
        blocks = [(name, sorted(tasks.values(), key=lambda runs: -sum(runs))) for name, tasks in modules.items()]
        sets[side] = sorted(blocks, key=lambda block: (-_share(block[1]), block[0]))
    return rows, sets, metrics


def _share(tasks: list[list[bool]]) -> float:
    return sum(map(sum, tasks)) / sum(map(len, tasks))


def _cell(s: Svg, x: float, y: float, size: float, passed: bool) -> None:
    if passed:
        s.rect(x, y, size, size, fill=INK)
    else:
        s.rect(x + 0.5, y + 0.5, size - 1, size - 1, fill="#fff", stroke=FAINT, width=1)


def _block(s: Svg, x: float, y: float, tasks: list[list[bool]], size: float, pitch: float) -> None:
    for row, runs in enumerate(tasks):
        for column, passed in enumerate(runs):
            _cell(s, x + column * pitch, y + row * pitch, size, passed)


def measures() -> None:
    """What is read from every run, and how runs add up: a run, a task's three runs, a module's tasks, a set."""
    _, sets, _ = _baseline()
    module = next(tasks for name, tasks in sets["B"] if name.startswith("Prob016"))
    task = next(runs for runs in module if sum(runs) == 2)
    s = Svg(1120, 312)
    # The four readings, in a panel that hangs from the run
    s.rect(0, 0, 1120, 96, fill=WASH, radius=8)
    readings = ((28, "Correctness", "a hidden testbench: pass or fail"), (316, "Tokens", "every model call in the run"),
                (560, "Time", "from the start to the answer"), (804, "Limitations", "what went wrong, read by the monitor"))
    for x, title, source in readings:
        s.text(x, 42, title, 21, 600)
        s.text(x, 68, source, 14.5, 400, SOFT)
    s.line([(36, 96), (36, 150)], stroke=SOFT, width=1.25, arrow=False)

    middle, columns = 186, (0, 270, 560, 826)
    _cell(s, columns[0], middle - 36, 72, task[0])
    for index, passed in enumerate(task):
        _cell(s, columns[1] + 56 * index, middle - 23, 46, passed)
    _block(s, columns[2], middle - 45, module, 26, 32)
    for index, (_, tasks) in enumerate(sets["B"]):
        _block(s, columns[3] + 38 * (index % 8), middle - 35 + 42 * (index // 8), tasks, 8, 10)
    for start, end in ((88, 254), (444, 544), (666, 810)):
        s.line([(start, middle), (end, middle)])

    captions = (("One run", "one attempt at one task"), ("One task", "three runs give its pass rate"),
                ("One module", "its tasks stay on one side of the split"), ("One set", "the mean over its tasks"))
    for x, (title, line) in zip(columns, captions):
        s.text(x, 276, title, 19, 600)
        s.text(x, 301, line, 15, 400, SOFT)
    s.save("measures.svg")


def baseline() -> None:
    """Every baseline run, by task and module, for each set; and what limited the runs that failed."""
    rows, sets, metrics = _baseline()
    s = Svg(1120, 400)
    left, size, pitch, step = 210, 12, 15, 54
    for y, side in ((0, "A"), (148, "B")):
        runs = [r for r in rows if r.side == side]
        passed = sum(r.passed for r in runs)
        tokens = sum(metrics.total_tokens(r.usage) for r in runs) / len(runs)
        seconds = sum(r.seconds for r in runs) / len(runs)
        s.text(0, y + 16, f"Set {side}", 17, 600)
        s.text(0, y + 66, f"{100 * passed / len(runs):.0f}%", 46, 600)
        s.text(0, y + 91, f"{passed} of {len(runs)} runs passed", 14.5, 400, SOFT)
        s.text(0, y + 111, f"{tokens / 1000:.0f}k tokens · {seconds:.0f} s per run", 14.5, 400, SOFT)
        groups: dict[str, list[int]] = {}
        for index, (_, tasks) in enumerate(sets[side]):
            _block(s, left + step * index, y + 6, tasks, size, pitch)
            share = _share(tasks)
            groups.setdefault("all" if share == 1 else "none" if share == 0 else "mixed", []).append(index)
        for kind, members in groups.items():
            x0, x1 = left + step * members[0], left + step * members[-1] + 2 * pitch + size
            s.line([(x0, y + 78), (x1, y + 78)], stroke=SOFT, width=1, arrow=False)
            count = len(members)
            noun = "module" if count == 1 else "modules"
            label = {"all": f"{count} {noun}: every run passed", "none": f"{count} {noun}: no run passed",
                     "mixed": f"{count} mixed"}[kind]
            s.text(x0, y + 97, label, 13.5, 400, SOFT)

    top = 296
    s.line([(0, top - 18), (1120, top - 18)], stroke=SOFT, width=1, arrow=False)
    s.text(0, top + 16, "Failed runs", 17, 600)
    s.text(0, top + 38, "what limited them,", 14.5, 400, SOFT)
    s.text(0, top + 57, "read by the monitor", 14.5, 400, SOFT)
    failed = {side: [r for r in rows if r.side == side and not r.passed] for side in "AB"}
    kinds = (("changed_more_than_the_bug", "Changed more than the bug"),
             ("test_did_not_test", "Own test missed the fault"), ("missed_the_bug", "Missed the bug"))
    for index, (key, title) in enumerate(kinds):
        x = left + 303 * index
        s.text(x, top + 16, title, 16, 600)
        for row, side in enumerate("AB"):
            y = top + 34 + 24 * row
            count = sum(key in (r.limitations or ()) for r in failed[side])
            s.text(x, y + 10, side, 13.5, 500, SOFT)
            s.rect(x + 20, y, 160, 10, fill="#ececec")
            s.rect(x + 20, y, 160 * count / len(failed[side]), 10, fill=INK)
            s.text(x + 190, y + 10, f"{count} of {len(failed[side])}", 13.5, 500)
    s.save("baseline_slide.svg")


def kb_axes() -> None:
    """The two choices that make a KB: what is written after a task, and how the next task reaches it."""
    s = Svg(1120, 356)
    s.rect(0, 0, 540, 356, fill=WASH, radius=8)
    s.rect(580, 0, 540, 356, fill=WASH, radius=8)
    s.text(32, 52, "Curation", 28, 600)
    s.text(32, 80, "what the agent keeps from a finished task", 16, 400, SOFT)
    s.text(612, 52, "Retrieval", 28, 600)
    s.text(612, 80, "how the next task finds it", 16, 400, SOFT)

    s.node(32, 116, 190, 88, "Finished task", ("the answer, the verdict", "and the correct fix"))
    s.node(898, 116, 190, 88, "Next task", ("opens the entries", "that bear on it"))
    s.line([(222, 160), (463, 160)], stroke=KB)
    s.line([(655, 160), (896, 160)], stroke=KB)
    s.text(342, 151, "writes", 11.5, 500, KB_TEXT, "middle", mono=True)
    s.text(776, 151, "reads", 11.5, 500, KB_TEXT, "middle", mono=True)
    s.node(465, 116, 190, 88, "Knowledge base", ("entries, arranged", "by an index"), "kb")

    s.line([(32, 238), (508, 238)], stroke=SOFT, width=1, arrow=False)
    s.line([(612, 238), (1088, 238)], stroke=SOFT, width=1, arrow=False)
    s.text(32, 270, "Entry type", 16, 600)
    s.text(120, 270, "what one entry holds", 14.5, 400, SOFT)
    s.text(32, 300, "Transcript  ·  Summary  ·  Note  ·  Rule", 15.5, 500)
    s.text(32, 324, "Page  ·  Skill  ·  Guide  ·  Step", 15.5, 500)
    s.text(612, 270, "Index", 16, 600)
    s.text(662, 270, "how entries are arranged and found", 14.5, 400, SOFT)
    s.text(612, 300, "Single file  ·  Flat files  ·  Catalogue  ·  Signature key", 15.5, 500)
    s.text(612, 324, "Tags  ·  Hierarchy  ·  Graph  ·  Similarity search", 15.5, 500)
    s.save("kb_axes.svg")


GRID_COLUMNS = ("Single file", "Flat files", "Catalogue", "Signature key", "Tags", "Hierarchy", "Graph",
                "Similarity search")
# A name: built and run. "o": defined, not run. "": the pair makes no sense.
GRID_ROWS = (
    ("What happened", "Transcript", ("Shared session", "Raw cases", "o", "o", "o", "o", "", "o")),
    ("", "Summary", ("o", "Summaries", "o", "o", "o", "o", "", "o")),
    ("What is true", "Note", ("o", "Notes", "o", "o", "o", "o", "o", "Notes by similarity")),
    ("", "Rule", ("Playbook", "", "", "o", "Rules by tags", "o", "", "o")),
    ("", "Page", ("", "o", "Wiki", "o", "o", "o", "Wiki, linked", "o")),
    ("What to do", "Skill", ("", "", "Skills", "o", "o", "Hierarchical skills", "o", "o")),
    ("", "Guide", ("Single-file guide", "o", "o", "Signature guides", "o", "o", "o", "o")),
    ("", "Step", ("o", "", "", "o", "", "Troubleshooting tree", "o", "")),
)


def kb_grid() -> None:
    """Entry type against index: the approaches built and run, those defined, and the pairs that make no sense."""
    s = Svg(1120, 400)
    x0, width, height, gap, top = 230, 106, 38, 6, 28
    for column, name in enumerate(GRID_COLUMNS):
        s.text(x0 + column * (width + gap) + width / 2, 14, name, 13.5, 500, SOFT, "middle")
    y = top
    for group, kind, cells in GRID_ROWS:
        if group and y > top:
            y += 12
        if group:
            s.text(0, y + 24, group, 14.5, 400, SOFT)
        s.text(128, y + 24, kind, 16, 600)
        for column, cell in enumerate(cells):
            x = x0 + column * (width + gap)
            if cell == "o":
                s.rect(x + 0.5, y + 0.5, width - 1, height - 1, fill="#fff", stroke=RULE, width=1, radius=4)
            elif cell:
                s.rect(x + 0.5, y + 0.5, width - 1, height - 1, fill=KB_WASH, stroke=KB, width=1.25, radius=4)
                words = cell.split(" ")
                lines = [cell] if len(cell) <= 14 else [" ".join(words[:-1]), words[-1]]
                for index, line in enumerate(lines):
                    s.text(x + width / 2, y + (24 if len(lines) == 1 else 16 + 15 * index), line, 12.5, 600, INK,
                           "middle")
        y += height + gap
    s.save("kb_grid.svg")


def _frozen(approach: str) -> Path:
    chain = ROOT / "runs" / f"kb-{approach}" / "kb" / "build" / "0"
    return chain / "snapshots" / json.loads((chain / "chain.json").read_text(encoding="utf-8"))["final"]


def kb_on_disk() -> None:
    """Two frozen KBs as files: the playbook, one file of rules with the middle one written out, and the
    hierarchical skills, a tree of folders."""
    import textwrap
    s = Svg(1120, 398)
    # The playbook: every rule a bar as long as the rule, one of them written out
    text = (_frozen("playbook") / "AGENTS.md").read_text(encoding="utf-8")
    rules = [line[2:].strip() for line in text.splitlines() if line.startswith("- ")]
    half = len(rules) // 2
    shown = min(range(half - 2, half + 3), key=lambda i: len(rules[i]))
    s.text(0, 20, "Playbook", 20, 600)
    s.text(0, 43, f"rules in a single file  ·  {len(rules)} rules, {len(text.split()):,} words", 14.5, 400, SOFT)
    s.rect(0, 58, 520, 304, fill="#fff", stroke=KB, width=1.25, radius=6)
    s.text(16, 81, "AGENTS.md", 12.5, 500, KB_TEXT, mono=True)
    s.line([(0, 93), (520, 93)], stroke=KB, width=1, arrow=False)
    y, longest = 106, max(map(len, rules))
    for index, rule in enumerate(rules):
        if index == shown:
            y += 5
            for line in textwrap.wrap(rule.replace("`", ""), 72):
                s.text(16, y + 11, line, 13.5, 500, KB_TEXT)
                y += 18
            y += 7
        else:
            s.rect(16, y, 488 * len(rule) / longest, 3, fill="#e2e3e5")
            y += 5.3
    s.text(0, 388, "All of it is in the agent's context on every task", 14.5, 400, SOFT)

    # The hierarchical skills: two groups, each with its skills; one branch opened
    root = _frozen("hierarchical-skills") / "skills"
    groups = sorted(p for p in root.iterdir() if p.is_dir())
    leaves = {g.name: sorted(p.name for p in g.iterdir() if p.is_dir()) for g in groups}
    words = sum(len(p.read_text(encoding="utf-8").split()) for p in root.rglob("SKILL.md"))
    s.text(600, 20, "Hierarchical skills", 20, 600)
    s.text(600, 43, f"skills in two levels  ·  {len(groups)} groups, {sum(map(len, leaves.values()))} skills, "
                    f"{words:,} words", 14.5, 400, SOFT)
    s.rect(600, 58, 520, 304, fill="#fff", stroke=FAINT, width=1, radius=6)
    s.text(616, 81, "skills/", 12.5, 500, SOFT, mono=True)
    s.line([(600, 93), (1120, 93)], stroke=RULE, width=1, arrow=False)
    opened = (groups[-1].name, leaves[groups[-1].name][-1])
    y = 106
    for group in groups:
        names = leaves[group.name]
        centres = [y + 13 + 29 * i for i in range(len(names))]
        middle = (centres[0] + centres[-1]) / 2
        for name, centre in zip(names, centres):
            on = (group.name, name) == opened
            if not on:
                s.line([(794, middle), (839, middle), (839, centre), (884, centre)], stroke=SOFT, width=1, arrow=False)
        for name, centre in zip(names, centres):
            on = (group.name, name) == opened
            if on:
                s.line([(794, middle), (839, middle), (839, centre), (882, centre)], stroke=KB, width=1.5)
            s.rect(884, centre - 13, 220, 26, fill=KB_WASH if on else "#fff", stroke=KB if on else FAINT,
                   width=1.25 if on else 1, radius=4)
            s.text(894, centre + 4, name, 12, 500 if on else 400, INK if on else SOFT, mono=True)
        s.rect(616, middle - 15, 178, 30, fill=KB_PALE, stroke=KB, width=1.25, radius=4)
        s.text(626, middle + 4, group.name, 12, 500, INK, mono=True)
        y = centres[-1] + 13 + 18
    s.text(600, 388, "The top level is in context; the agent opens the branch that fits the task", 14.5, 400, SOFT)
    s.save("kb_on_disk.svg")


def results() -> None:
    """Each approach on set B against the baseline: points gained with its interval, tokens and time, ranked by
    gain and then by tokens; and gain against tokens, with the Pareto frontier."""
    import sys
    sys.path.insert(0, str(ROOT))
    from harness.report.figures import approach_name
    data = json.loads((ROOT / "reports" / "main" / "summary.json").read_text(encoding="utf-8"))["comparisons"]
    rows = []
    for name, entry in data.items():
        against = entry["vs_baseline"]
        gain = against["pass_rate_difference"]
        rows.append({"name": approach_name(name), "gain": round(100 * gain["value"], 4), "low": 100 * gain["low"],
                     "high": 100 * gain["high"], "tokens": against["token_ratio"]["value"],
                     "time": against["time_ratio"]["value"]})
    rows.sort(key=lambda r: (-r["gain"], r["tokens"]))
    frontier = [r for r in rows if not any(
        o["gain"] >= r["gain"] and o["tokens"] <= r["tokens"] and (o["gain"] > r["gain"] or o["tokens"] < r["tokens"])
        for o in rows)]
    grid = "#e2e3e5"
    s = Svg(1120, 424)

    # Left: the ranking
    x0, unit, top, pitch = 214, 6.4, 44, 27
    bottom = top + pitch * len(rows) - 6
    s.text(x0, 14, "Pass rate on set B, points gained", 13.5, 500, SOFT)
    s.text(590, 14, "Tokens", 13.5, 500, SOFT, "end")
    s.text(656, 14, "Time", 13.5, 500, SOFT, "end")
    for tick in (0, 10, 20, 30, 40):
        if tick:
            s.line([(x0 + tick * unit, top - 8), (x0 + tick * unit, bottom)], stroke=grid, width=1, arrow=False)
        s.text(x0 + tick * unit, bottom + 18, str(tick), 12.5, 400, SOFT, "middle")
    s.line([(x0, top - 8), (x0, bottom)], stroke=INK, width=1.25, arrow=False)
    for index, r in enumerate(rows):
        y = top + pitch * index + 8
        sure = r["low"] > 0
        s.text(16, y + 5, str(index + 1), 13, 500, FAINT, "end")
        s.text(26, y + 5, r["name"], 15, 600 if r in frontier else 400)
        s.line([(x0 + max(r["low"], 0) * unit, y), (x0 + r["high"] * unit, y)], stroke=KB, width=2, arrow=False)
        s.parts.append(f'<circle cx="{x0 + r["gain"] * unit:.1f}" cy="{y}" r="5.5" fill="{KB if sure else "#fff"}" '
                       f'stroke="{KB}" stroke-width="2"/>')
        s.text(x0 + 40 * unit + 14, y + 5, f"+{r['gain']:.0f}", 14, 600 if sure else 400, INK if sure else SOFT)
        s.text(590, y + 5, f"{r['tokens']:.2f}\u00d7", 14, 400, INK, "end")
        s.text(656, y + 5, f"{r['time']:.2f}\u00d7", 14, 400, INK, "end")

    # Right: gain against tokens, each dot numbered by its rank
    left, right, floor, far = 742, 1062, 372, 1100
    px = lambda tokens: far if tokens > 1.8 else left + (tokens - 1.1) / 0.7 * (right - left)
    py = lambda gain: floor - gain * 15
    s.text(712, 14, "Points gained against tokens per run", 13.5, 500, SOFT)
    steps = sorted(frontier, key=lambda r: r["tokens"])
    path = [(px(steps[0]["tokens"]), floor)]
    for r in steps:
        path += [(px(r["tokens"]), path[-1][1]), (px(r["tokens"]), py(r["gain"]))]
    path.append((1120, path[-1][1]))
    area = " ".join(f"{x:.1f},{y:.1f}" for x, y in path + [(1120, floor)])
    s.parts.append(f'<polygon points="{area}" fill="#f6f6f6"/>')
    for tick in (0, 5, 10, 15, 20):
        s.line([(726, py(tick)), (1120, py(tick))], stroke=INK if tick == 0 else grid, width=1, arrow=False)
        s.text(718, py(tick) + 4, str(tick), 12.5, 400, SOFT, "end")
    for tick in (1.2, 1.4, 1.6, 1.8):
        s.text(px(tick), floor + 20, f"{tick:.1f}\u00d7", 12.5, 400, SOFT, "middle")
    s.line(path[1:], stroke=INK, width=1.25, arrow=False)
    s.text(1120, path[-1][1] - 9, "Pareto frontier", 12.5, 500, SOFT, "end")
    placed: list[tuple[float, float]] = []
    for index, r in enumerate(rows):
        x, y = px(r["tokens"]), py(r["gain"])
        while any(abs(x - ox) < 20 and abs(y - oy) < 20 for ox, oy in placed):
            x += 21
        placed.append((x, y))
        on = r in frontier
        s.parts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="10" fill="{KB if on else KB_WASH}" stroke="{KB}" '
                       f'stroke-width="1.25"/>')
        s.text(round(x, 1), round(y + 4, 1), str(index + 1), 11.5, 600, "#fff" if on else INK, "middle")
        if r["tokens"] > 1.8:
            s.text(x, floor + 20, f"{r['tokens']:.1f}\u00d7", 12.5, 400, SOFT, "middle")
    s.text(left + (right - left) / 2, floor + 44, "Tokens per run, ratio to no KB", 12.5, 400, SOFT, "middle")
    s.save("results_slide.svg")


if __name__ == "__main__":
    experiment()
    architecture()
    run()
    monitor()
    measures()
    baseline()
    kb_axes()
    kb_grid()
    kb_on_disk()
    results()
    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("*.svg"))))
