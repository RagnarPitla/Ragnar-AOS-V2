#!/usr/bin/env bash
# RAOS V2 Scaffold — headless-copilot.sh
# Entry point for unattended scheduled runs via GitHub Copilot CLI.
#
# NOTE: GitHub Copilot CLI (`gh copilot`) does not have a headless/print mode
# equivalent to `claude -p`. For truly unattended runs, use GitHub Actions
# with the template at harness/schedule/github-actions.yaml.template.
#
# This script exists as a best-effort wrapper. It:
#   1. Validates the run exists
#   2. Marks it active
#   3. Attempts to invoke gh copilot suggest (non-interactive fallback)
#   4. Logs output
#
# For production headless runs, prefer GitHub Actions.
#
# Usage:
#   headless-copilot.sh <project_root> <run_id>

set -u

PROJECT_ROOT="${1:-}"
RUN_ID="${2:-}"

if [ -z "$PROJECT_ROOT" ] || [ -z "$RUN_ID" ]; then
  echo "headless-copilot.sh: usage: headless-copilot.sh <project_root> <run_id>" >&2
  exit 1
fi

command -v gh >/dev/null 2>&1 || { echo "headless-copilot.sh: gh CLI not on PATH" >&2; exit 1; }
gh extension list 2>/dev/null | grep -q copilot || { echo "headless-copilot.sh: gh copilot extension not installed. Run: gh extension install github/gh-copilot" >&2; exit 1; }

cd "$PROJECT_ROOT" || exit 1

RUNS_DIR="$PROJECT_ROOT/.agentic-os/runs"
[ -d "$RUNS_DIR/$RUN_ID" ] || { echo "headless-copilot.sh: run $RUN_ID not found in $RUNS_DIR" >&2; exit 1; }

echo "$RUN_ID" > "$RUNS_DIR/.active"
LOG="$RUNS_DIR/$RUN_ID/headless.log"

{
  echo "=== headless run at $(date -u +"%Y-%m-%dT%H:%M:%SZ") ==="
  echo "NOTE: gh copilot does not support headless mode natively."
  echo "For production headless runs, use GitHub Actions (see harness/schedule/github-actions.yaml.template)."
  echo "Attempting best-effort invocation..."
  gh copilot suggest "/raos resume $RUN_ID" --shell 2>&1 || echo "gh copilot suggest exited with code $?"
  echo "=== headless run ended ==="
} >> "$LOG"
