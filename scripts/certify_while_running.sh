#!/usr/bin/env bash
# Certifies and assesses finished KB runs while the rest are still running, so
# that little is left once the last run ends. Runs are read only once their
# record is written, so a run in progress is never touched. Start it detached:
#
#   setsid nohup scripts/certify_while_running.sh >> ~/rcakb-logs/certify.log 2>&1 &

set -u
export PATH="$HOME/.local/bin:$PATH"
export UV_PROJECT_ENVIRONMENT="${UV_PROJECT_ENVIRONMENT:-$HOME/.venvs/rcakb}"
cd "$(dirname "$0")/.."
ALL="shared-session raw-cases summaries notes note-similarity playbook rule-tags wiki skills hierarchical-skills guide-single-file signature-guides troubleshooting-tree"
while pgrep -f "scripts/run_approaches.sh" > /dev/null; do
    for a in $ALL; do
        m=$(uv run -q python -m harness.cli monitor "kb-$a" --parallel 8 2>&1 | tail -n 1)
        s=$(uv run -q python -m harness.cli assess "kb-$a" --parallel 8 2>&1 | tail -n 1)
        echo "$(date +%H:%M:%S) $a | $m | $s"
    done
    sleep 120
done
echo "$(date +%H:%M:%S) runs finished; certify_and_report.sh does the rest"
