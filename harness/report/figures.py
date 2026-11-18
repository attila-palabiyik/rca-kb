"""The report's figures, drawn from the same rows and numbers as its tables.

Each figure is saved as SVG and PNG. The SVG keeps its text as text, so a page
that places it inline sets it in its own type. Figures are laid out in Libre
Franklin when its files are in .cache/fonts (scripts/build_report_pdf.py
prints the pages in it), and fall back to a system sans otherwise.

Colour has one meaning throughout: the accent is a run with a KB. The baseline
is drawn in ink and grey.

    baseline_tasks              every baseline task, by module and bug category
    baseline_limitations        what limited baseline runs that failed and that passed
    approaches_vs_baseline      each approach against the baseline on B: pass rate, tokens, time
    approaches_vs_baseline_slide  the same, shaped for a slide
    tasks_by_approach           every task on B, with each approach's change against the baseline
    seen_and_unseen             the build's runs on A by whether the module was met before, and B
"""

from __future__ import annotations

import logging
import re
from collections import defaultdict
from pathlib import Path
from statistics import mean

from .metrics import Row

INK, SOFT, FAINT, GRID = "#1a1f24", "#5c6770", "#8b949b", "#d9d9d9"
GREY, NONE, ACCENT, PALE = "#a9b1b8", "#e9ebec", "#0b7a75", "#cfe6e4"
FAMILY = ["Libre Franklin", "Franklin Gothic Medium", "Segoe UI", "Helvetica Neue", "Arial", "DejaVu Sans"]
WIDTH = 6.3  # inches: the written report's full width, so 8 pt here is 8 pt there
HEAD, LABEL, SMALL = 8.5, 8, 7  # the three type sizes

STYLE = {
    "font.family": "sans-serif", "font.sans-serif": FAMILY, "font.size": LABEL,
    "svg.fonttype": "none", "svg.hashsalt": "rcakb",
    "axes.spines.top": False, "axes.spines.right": False, "axes.spines.left": False,
    "axes.spines.bottom": False, "axes.labelcolor": SOFT, "axes.labelsize": SMALL, "axes.axisbelow": True,
    "xtick.color": SOFT, "ytick.color": INK, "xtick.labelsize": SMALL, "ytick.labelsize": LABEL,
    "xtick.major.size": 0, "ytick.major.size": 0, "grid.color": GRID, "grid.linewidth": 0.5,
    "text.color": INK, "legend.fontsize": SMALL, "legend.frameon": False,
}

NAMES = {"guide-single-file": "Single-file guide", "note-similarity": "Notes by similarity",
         "rule-tags": "Rules by tags"}
LABELS = {"test_did_not_test": "Own test missed the fault", "kb_ignored": "Ignored the KB",
          "kb_no_help": "KB did not help", "kb_misled": "Misled by the KB"}
FONTS = Path(__file__).resolve().parents[2] / ".cache" / "fonts"


def approach_name(experiment: str) -> str:
    """kb-rule-tags -> Rules by tags."""
    key = experiment.removeprefix("kb-").split("/")[0]
    return NAMES.get(key, key.replace("-", " ").capitalize())


def limitation_label(category: str) -> str:
    return LABELS.get(category, category.replace("_", " ").capitalize())


def _register_fonts() -> None:
    from matplotlib import font_manager

    for file in sorted(FONTS.glob("*.ttf")):
        font_manager.fontManager.addfont(str(file))


def _tint(passes: int, runs: int) -> str:
    """Ink for a task that passed every run, grey for some, near white for none."""
    return NONE if passes == 0 else INK if passes == runs else GREY


def _number(group: str) -> str:
    found = re.search(r"\d+", group)
    return str(int(found.group())) if found else ""


def _bare(axis) -> None:
    axis.set_xticks([])
    axis.set_yticks([])


def _cell(axis, x: float, y: float, colour: str, edge: str | None = None) -> None:
    from matplotlib.patches import Rectangle

    axis.add_patch(Rectangle((x + 0.06, y + 0.06), 0.88, 0.88, facecolor=colour,
                             edgecolor=edge or "none", linewidth=0.6 if edge else 0))


def _heading(axis, title: str, detail: str, above: float) -> None:
    """A bold word with a plain phrase after it, set above the axis."""
    first = axis.annotate(title, (0, 1 + above), xycoords="axes fraction", fontsize=HEAD,
                          fontweight="bold", va="bottom")
    axis.annotate(detail, (1, 0), xycoords=first, xytext=(5, 0), textcoords="offset points",
                  fontsize=LABEL, color=SOFT, va="bottom")


def _legend(figure, items: list[tuple[str, str] | tuple[str, str, str]], x: float, title: str | None = None) -> None:
    from matplotlib.patches import Patch

    handles = [Patch(facecolor=item[1], edgecolor=item[2] if len(item) > 2 else "none", linewidth=0.6,
                     label=item[0]) for item in items]
    figure.legend(handles=handles, ncol=len(handles), loc="lower left", bbox_to_anchor=(x, 0.0),
                  handlelength=0.9, handleheight=0.9, columnspacing=1.4, handletextpad=0.5,
                  borderaxespad=0.2, title=title, title_fontsize=SMALL, alignment="left")


def draw(report: dict, rows: list[Row], folder: Path) -> None:
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        return
    logging.getLogger("matplotlib.font_manager").setLevel(logging.ERROR)
    _register_fonts()

    def save(figure, name: str) -> None:
        folder.mkdir(parents=True, exist_ok=True)
        figure.savefig(folder / f"{name}.png", dpi=220)
        figure.savefig(folder / f"{name}.svg", metadata={"Date": None})
        plt.close(figure)

    baseline = [r for r in rows if r.mode == "baseline"]
    with plt.rc_context(STYLE):
        if baseline:
            _baseline_tasks(plt, baseline, save)
            _baseline_limitations(plt, baseline, save)
        order = _order(report)
        if order:
            _approaches_vs_baseline(plt, report, order, save, "approaches_vs_baseline", line=0.215)
            _approaches_vs_baseline(plt, report, order, save, "approaches_vs_baseline_slide", line=0.15)
            _tasks_by_approach(plt, rows, baseline, order, save)
            _seen_and_unseen(plt, report, order, save)


def _order(report: dict) -> list[str]:
    """Experiments compared with the baseline, the largest gain in pass rate first."""
    compared = [(name, entry["vs_baseline"]["pass_rate_difference"]["value"] or 0.0)
                for name, entry in report["comparisons"].items()
                if (entry.get("vs_baseline") or {}).get("tasks")]
    return [name for name, _ in sorted(compared, key=lambda item: (-item[1], item[0]))]


def _modules(rows: list[Row]) -> tuple[list[str], dict]:
    """Modules ordered by pass rate, each with its runs' outcomes by bug category."""
    modules = defaultdict(lambda: defaultdict(list))
    for row in rows:
        modules[row.group][row.tags.get("category", "")].append(row.passed)
    share = {m: mean(p for runs in cells.values() for p in runs) for m, cells in modules.items()}
    return sorted(modules, key=lambda m: (-share[m], m)), modules


def _baseline_tasks(plt, baseline: list[Row], save) -> None:
    sides = sorted({r.side for r in baseline})
    categories = sorted({r.tags.get("category", "") for r in baseline})
    laid = {side: _modules([r for r in baseline if r.side == side]) for side in sides}
    columns = [len(laid[side][0]) for side in sides]
    left, gap, top, bottom = 1.05, 0.4, 0.3, 0.45
    unit = (WIDTH - left - gap * (len(sides) - 1) - 0.05) / sum(columns)
    height = top + bottom + unit * len(categories)
    figure = plt.figure(figsize=(WIDTH, height))
    x = left
    repeats = max(len(runs) for side in sides for cells in laid[side][1].values() for runs in cells.values())
    for index, side in enumerate(sides):
        order, modules = laid[side]
        axis = figure.add_axes([x / WIDTH, bottom / height, unit * len(order) / WIDTH, unit * len(categories) / height])
        for column, module in enumerate(order):
            for line, category in enumerate(categories):
                runs = modules[module].get(category)
                if runs:
                    _cell(axis, column, line, _tint(sum(runs), len(runs)))
            axis.text(column + 0.5, len(categories) + 0.2, _number(module), fontsize=SMALL, color=SOFT,
                      ha="center", va="top")
        axis.set_xlim(0, len(order))
        axis.set_ylim(len(categories), 0)
        _bare(axis)
        if index == 0:
            axis.set_yticks([line + 0.5 for line in range(len(categories))],
                            [c.replace("_", " ").capitalize() for c in categories])
        mine = [r for r in baseline if r.side == side]
        tasks = len({r.task_id for r in mine})
        _heading(axis, f"Set {side}", f"{tasks} tasks in {len(order)} modules, "
                                       f"{100 * mean(r.passed for r in mine):.0f}% pass",
                 0.07 / (unit * len(categories)))
        x += unit * len(order) + gap
    _legend(figure, [(f"all {repeats}", INK), ("some", GREY), ("none", NONE)], left / WIDTH,
            title=None)
    figure.text(left / WIDTH - 0.01, 0.1 / height, f"Runs passed, of {repeats}", fontsize=SMALL, color=SOFT,
                ha="right", va="center")
    save(figure, "baseline_tasks")


def _baseline_limitations(plt, baseline: list[Row], save) -> None:
    assessed = [r for r in baseline if r.limitations is not None]
    if not assessed:
        return
    sides = sorted({r.side for r in assessed})

    def share(rows: list[Row], category: str) -> float:
        return 100 * mean(1.0 if category in r.limitations else 0.0 for r in rows) if rows else 0.0

    failed_all = [r for r in assessed if not r.passed]
    categories = sorted({c for r in assessed for c in r.limitations if c != "other"},
                        key=lambda c: (-share(failed_all, c), c))
    left, gap, top, bottom, line = 1.95, 0.45, 0.5, 0.28, 0.27
    height = top + bottom + line * len(categories)
    panel = (WIDTH - left - gap * (len(sides) - 1) - 0.3) / len(sides)
    figure = plt.figure(figsize=(WIDTH, height))
    for index, side in enumerate(sides):
        axis = figure.add_axes([(left + index * (panel + gap)) / WIDTH, bottom / height,
                                panel / WIDTH, line * len(categories) / height])
        failed = [r for r in assessed if r.side == side and not r.passed]
        passed = [r for r in assessed if r.side == side and r.passed]
        for position, category in enumerate(categories):
            f, p = share(failed, category), share(passed, category)
            close = abs(f - p) < 4
            axis.plot([p, f], [position, position], color=GRID, linewidth=2.0, solid_capstyle="round", zorder=1)
            axis.plot(f, position, "o", color=INK, markersize=5.5, markeredgecolor="white", markeredgewidth=0.8, zorder=3)
            axis.plot(p, position, "o", color="white", markersize=5, markeredgecolor=SOFT, markeredgewidth=1.1,
                      zorder=5 if close else 2)
            f_right = f >= p
            axis.annotate(f"{f:.0f}%", (f, position), xytext=(6 if f_right else -6, 0), textcoords="offset points",
                          ha="left" if f_right else "right", va="center", fontsize=LABEL, fontweight="bold")
            axis.annotate(f"{p:.0f}%", (p, position), xytext=(-6 if f_right else 6, 0), textcoords="offset points",
                          ha="right" if f_right else "left", va="center", fontsize=LABEL, color=SOFT)
            if index == 0 and position == 0:
                axis.annotate("runs that failed", (f, position), xytext=(0, 8), textcoords="offset points",
                              ha="center", fontsize=SMALL, fontweight="bold")
                axis.annotate("runs that passed", (p, position), xytext=(0, 8), textcoords="offset points",
                              ha="center", fontsize=SMALL, color=SOFT)
        axis.set_xlim(-6, 112)
        axis.set_ylim(len(categories) - 0.5, -0.5)
        axis.set_xticks([0, 50, 100], ["0", "50", "100%"])
        axis.grid(axis="x")
        axis.set_yticks(range(len(categories)), [limitation_label(c) for c in categories] if index == 0 else [])
        axis.tick_params(axis="y", pad=24)
        _heading(axis, f"Set {side}", f"{len(failed)} runs failed, {len(passed)} passed",
                 0.3 / (line * len(categories)))
    save(figure, "baseline_limitations")


def _interval_rows(axis, entries: list[dict | None], scale: float, reference: float, pattern: str,
                   log: bool = False) -> None:
    """One dot and interval per row; filled where the interval excludes the reference."""
    for position, entry in enumerate(entries):
        if not entry or entry.get("value") is None:
            continue
        value, low, high = (scale * entry[k] for k in ("value", "low", "high"))
        apart = low > reference or high < reference
        axis.plot([low, high], [position, position], color=ACCENT, linewidth=1.3, solid_capstyle="butt", zorder=2)
        axis.plot(value, position, "o", markersize=5, color=ACCENT if apart else "white",
                  markeredgecolor=ACCENT, markeredgewidth=1.2, zorder=3)
        shown = pattern.format(value).replace("-", "−")
        axis.text(1.03, position, "0" if shown.strip("+−") == "0" else shown,
                  transform=axis.get_yaxis_transform(), fontsize=LABEL, va="center", ha="left",
                  color=INK if apart else SOFT, fontweight="bold" if apart else "normal")
    axis.axvline(reference, color=INK, linewidth=0.75, zorder=1)
    for position in range(len(entries) - 1):
        axis.axhline(position + 0.5, color="#eeeeee", linewidth=0.4, zorder=0)
    axis.set_ylim(len(entries) - 0.5, -0.5)
    axis.grid(axis="x")
    axis.margins(x=0.08)
    if log:
        axis.set_xscale("log")
        axis.minorticks_off()
        low, high = axis.get_xlim()
        low, high = min(low, 0.9), max(high, 1.15)
        axis.set_xlim(low, high)
        ladder = [0.25, 0.5, 0.8, 1, 1.25, 1.6, 2, 3, 5, 8, 12, 20]
        ticks = [t for t in ladder if low <= t <= high]
        while len(ticks) > 5:  # thin out, always keeping 1
            ticks = [t for i, t in enumerate(ticks) if t == 1 or i % 2 == 0]
        labels = [f"{t:g}" for t in ticks]
        labels[-1] += "×"
        axis.set_xticks(ticks, labels)


def _panel_title(axis, title: str, unit: str, rows: int, line: float) -> None:
    axis.text(0, 1.0 + 0.3 / (line * rows), title, transform=axis.transAxes, fontsize=HEAD,
              fontweight="bold", va="bottom")
    axis.text(0, 1.0 + 0.13 / (line * rows), unit, transform=axis.transAxes, fontsize=SMALL,
              color=SOFT, va="bottom")


def _approaches_vs_baseline(plt, report: dict, order: list[str], save, name: str, line: float) -> None:
    base = report["conditions"].get("baseline", {}).get("B", {}).get("pass_rate")
    start = f"change from {100 * base:.0f}%, points" if base is not None else "change in pass rate, points"
    panels = [("Correctness", start, "pass_rate_difference", 100.0, 0.0, "{:+.0f}", False),
              ("Tokens per run", "ratio to no KB, lower is cheaper", "token_ratio", 1.0, 1.0, "{:.2f}×", True),
              ("Time to solution", "ratio to no KB, lower is faster", "time_ratio", 1.0, 1.0, "{:.2f}×", True)]
    left, gap, right, top, bottom = 1.35, 0.62, 0.45, 0.5, 0.3
    height = top + bottom + line * len(order)
    share = (WIDTH - left - right - 2 * gap) / 3.3
    widths = [1.5 * share, 0.9 * share, 0.9 * share]
    figure = plt.figure(figsize=(WIDTH, height))
    x = left
    for index, (title, unit, key, scale, reference, pattern, log) in enumerate(panels):
        axis = figure.add_axes([x / WIDTH, bottom / height, widths[index] / WIDTH, line * len(order) / height])
        _interval_rows(axis, [report["comparisons"][n]["vs_baseline"].get(key) for n in order],
                       scale, reference, pattern, log)
        axis.set_yticks(range(len(order)), [approach_name(n) for n in order] if index == 0 else [])
        _panel_title(axis, title, unit, len(order), line)
        x += widths[index] + gap
    save(figure, name)


def _tasks_by_approach(plt, rows: list[Row], baseline: list[Row], order: list[str], save) -> None:
    base = [r for r in baseline if r.side == "B"]
    if not base:
        return
    modules, cells = _modules(base)
    categories = sorted({r.tags.get("category", "") for r in base})
    columns, x, starts = {}, 0.0, []
    for module in modules:
        starts.append(x)
        for category in categories:
            if cells[module].get(category):
                columns[(module, category)] = x
                x += 1
        x += 0.45
    total = x - 0.45
    by_task = defaultdict(lambda: defaultdict(list))
    for row in base:
        by_task["baseline"][(row.group, row.tags.get("category", ""))].append(row.passed)
    for row in rows:
        if row.experiment in order and row.mode == "eval" and row.side == "B" and row.condition != "empty":
            by_task[row.experiment][(row.group, row.tags.get("category", ""))].append(row.passed)
    names = ["baseline", *order]
    left, right, top, bottom, line_height = 1.35, 0.5, 0.05, 0.45, 0.145
    unit = (WIDTH - left - right) / total
    lines = [0.0] + [position + 0.5 for position in range(1, len(names))]
    height = top + bottom + line_height * (lines[-1] + 1)
    figure = plt.figure(figsize=(WIDTH, height))
    axis = figure.add_axes([left / WIDTH, bottom / height, total * unit / WIDTH,
                            line_height * (lines[-1] + 1) / height])
    for name, line in zip(names, lines):
        runs = [p for outcomes in by_task[name].values() for p in outcomes]
        for key, column in columns.items():
            outcomes = by_task[name].get(key)
            if not outcomes:
                continue
            reference = by_task["baseline"][key]
            if name == "baseline":
                _cell(axis, column, line, _tint(sum(outcomes), len(outcomes)))
                continue
            now, before = mean(outcomes), mean(reference)
            if now > before:
                _cell(axis, column, line, ACCENT)                  # gained
            elif now < before:
                _cell(axis, column, line, "white", edge=INK)       # lost
            else:
                _cell(axis, column, line, PALE if now > 0 else NONE)  # kept, or failed both
        axis.text(total + 0.8, line + 0.5, f"{100 * mean(runs):.0f}%" if runs else "", fontsize=LABEL,
                  va="center", ha="left", fontweight="bold" if name == "baseline" else "normal")
    for module, start in zip(modules, starts):
        width = sum(1 for category in categories if cells[module].get(category))
        axis.text(start + width / 2, lines[-1] + 1.25, _number(module), fontsize=SMALL, color=SOFT,
                  ha="center", va="top")
    axis.set_xlim(0, total)
    axis.set_ylim(lines[-1] + 1, 0)
    _bare(axis)
    axis.set_yticks([line + 0.5 for line in lines], ["No KB", *[approach_name(n) for n in order]])
    _legend(figure, [("more often than with no KB", ACCENT), ("as often", PALE),
                     ("less often", "white", INK), ("failed with both", NONE)], left / WIDTH)
    figure.text(left / WIDTH - 0.01, 0.1 / height, "Passed", fontsize=SMALL, color=SOFT, ha="right", va="center")
    save(figure, "tasks_by_approach")


def _seen_and_unseen(plt, report: dict, order: list[str], save) -> None:
    def part(name: str, key: str) -> dict | None:
        if key == "B":
            return report["comparisons"][name]["vs_baseline"]
        return ((report["kb"].get(name) or {}).get("seen_and_unseen") or {}).get(key)

    if not any(part(n, "seen") for n in order):
        return
    panels = [("seen", "Set A, module met before"), ("first", "Set A, module new to the KB"),
              ("B", "Set B, every module new")]
    left, gap, right, top, bottom, line = 1.35, 0.5, 0.45, 0.5, 0.3, 0.17
    height = top + bottom + line * len(order)
    width = (WIDTH - left - right - 2 * gap) / 3
    figure = plt.figure(figsize=(WIDTH, height))
    axes = []
    for index, (key, title) in enumerate(panels):
        axis = figure.add_axes([(left + index * (width + gap)) / WIDTH, bottom / height,
                                width / WIDTH, line * len(order) / height], sharex=axes[0] if axes else None)
        entries = [part(n, key) for n in order]
        _interval_rows(axis, [(e or {}).get("pass_rate_difference") for e in entries], 100.0, 0.0, "{:+.0f}")
        tasks = next((e.get("tasks") for e in entries if e and e.get("tasks")), None)
        _panel_title(axis, title, f"{tasks} tasks, change in points" if tasks else "change in points",
                     len(order), line)
        axis.set_yticks(range(len(order)), [approach_name(n) for n in order] if index == 0 else [])
        axes.append(axis)
    save(figure, "seen_and_unseen")
