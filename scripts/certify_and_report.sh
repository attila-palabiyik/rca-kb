#!/usr/bin/env bash
# Reviews and assesses the runs of a set of KB approaches, then builds the
# report that compares them with the baseline. No agent is run.
#
#   scripts/certify_and_report.sh notes playbook skills
#
# Logs go to ~/rcakb-logs/.

set -u
export PATH="$HOME/.local/bin:$PATH"
export UV_PROJECT_ENVIRONMENT="${UV_PROJECT_ENVIRONMENT:-$HOME/.venvs/rcakb}"
cd "$(dirname "$0")/.."
logs="$HOME/rcakb-logs"
mkdir -p "$logs"

experiments=()
for approach in "$@"; do
    name="kb-$approach"
    experiments+=("$name")
    uv run -q python -m harness.cli monitor "$name" --parallel 12 >> "$logs/$approach.review.log" 2>&1
    uv run -q python -m harness.cli assess "$name" --parallel 12 >> "$logs/$approach.review.log" 2>&1
    echo "$(date +%H:%M:%S) $approach: $(tail -2 "$logs/$approach.review.log" | tr '\n' ' ')"
done

uv run -q python -m harness.cli report baseline "${experiments[@]}" --out reports/main --write-up docs/report.md
echo "$(date +%H:%M:%S) report built"
