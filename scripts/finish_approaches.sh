#!/usr/bin/env bash
# Finishes a set of KB approaches and reports them: runs whatever is not yet
# recorded, then certifies, assesses and reports every approach named in ALL.
# Meant to be started detached, so that it outlives the shell that started it:
#
#   setsid nohup scripts/finish_approaches.sh > ~/rcakb-logs/finish.log 2>&1 &

set -u
cd "$(dirname "$0")/.."
ALL="shared-session raw-cases summaries notes note-similarity playbook rule-tags wiki skills hierarchical-skills guide-single-file signature-guides troubleshooting-tree"
TODO="summaries notes note-similarity playbook rule-tags wiki skills hierarchical-skills guide-single-file signature-guides troubleshooting-tree"
sed -i 's/\r$//' scripts/run_approaches.sh scripts/certify_and_report.sh
scripts/run_approaches.sh $TODO
scripts/certify_and_report.sh $ALL
echo "$(date +%H:%M:%S) finished"
