#!/usr/bin/env bash
# RAOS V2 Scaffold — headless.sh
# Entry point for unattended scheduled runs. Intended to be wrapped by launchd,
# Windows Task Scheduler, or GitHub Actions.
#
# Usage:
#   headless.sh <project_root> <run_id>
#
# Behavior:
#   - cd to the project
#   - Mark <run_id> active
#   - Invoke Claude Code in print mode with /raos resume <run_id>
#   - Append the session output to .agentic-os/runs/<run_id>/headless.log
#   - Exit non-zero if Claude Code is not on PATH.

set -u

PROJECT_ROOT="${1:-}"
RUN_ID="${2:-}"

if [ -z "$PROJECT_ROOT" ] || [ -z "$RUN_ID" ]; then
  echo "headless.sh: usage: headless.sh <project_root> <run_id>" >&2
  exit 1
fi

command -v claude >/dev/null 2>&1 || { echo "headless.sh: claude CLI not on PATH" >&2; exit 1; }

cd "$PROJECT_ROOT" || exit 1

RUNS_DIR="$PROJECT_ROOT/.agentic-os/runs"
[ -d "$RUNS_DIR/$RUN_ID" ] || { echo "headless.sh: run $RUN_ID not found in $RUNS_DIR" >&2; exit 1; }

echo "$RUN_ID" > "$RUNS_DIR/.active"
LOG="$RUNS_DIR/$RUN_ID/headless.log"

{
  echo "=== headless run at $(date -u +"%Y-%m-%dT%H:%M:%SZ") ==="
  claude -p "/raos resume $RUN_ID" 2>&1
  echo "=== headless run exit code: $? ==="
} >> "$LOG"
