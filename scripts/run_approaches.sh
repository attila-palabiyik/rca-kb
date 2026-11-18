#!/usr/bin/env bash
# Runs a set of KB approaches: every build chain at once, then each approach's
# frozen runs on B, one approach after another so the machine is never asked
# for more than one batch at a time. Restarting skips whatever is recorded.
#
#   scripts/run_approaches.sh notes playbook skills
#
# Logs go to ~/rcakb-logs/.

set -u
export PATH="$HOME/.local/bin:$PATH"
export UV_PROJECT_ENVIRONMENT="${UV_PROJECT_ENVIRONMENT:-$HOME/.venvs/rcakb}"
cd "$(dirname "$0")/.."
logs="$HOME/rcakb-logs"
mkdir -p "$logs"

echo "$(date +%H:%M:%S) building: $*"
for approach in "$@"; do
    uv run -q python -m harness.cli run "configs/experiments/kb-$approach.toml" --conditions build \
        >> "$logs/$approach.build.log" 2>&1 &
done
wait
echo "$(date +%H:%M:%S) chains finished"

for approach in "$@"; do
    uv run -q python -m harness.cli run "configs/experiments/kb-$approach.toml" --conditions eval \
        >> "$logs/$approach.eval.log" 2>&1
    echo "$(date +%H:%M:%S) $approach: $(grep -c 'verdict pass' "$logs/$approach.eval.log") of $(grep -c 'verdict' "$logs/$approach.eval.log") pass on B"
done
echo "$(date +%H:%M:%S) done"
