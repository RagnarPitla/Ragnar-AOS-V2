#!/usr/bin/env bash
# RAOS V2 Scaffold — UserPromptSubmit hook
# Responsibilities:
#   1. Detect `/raos resume <run_id>` and mark that run active
#   2. Detect `/raos kill <run_id>` and drop a KILL sentinel in that run
#   3. Print a one-line banner the team-lead sees at the top of its next turn,
#      surfacing the active run's manifest path + current phase.
#
# Notes:
#   - This hook does not modify the user's prompt. It writes sentinel files
#     that the skill's own logic reads.
#   - Exit 0 always. Never block on parse errors.

set -u

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
RUNS_DIR="$PROJECT_ROOT/.agentic-os/runs"
ACTIVE_FILE="$RUNS_DIR/.active"
PROMPT="${USER_PROMPT:-}"

[ -d "$RUNS_DIR" ] || exit 0

# 1. /raos resume <run_id>
if echo "$PROMPT" | grep -qE '^/raos[[:space:]]+resume[[:space:]]+[A-Za-z0-9._-]+'; then
  TARGET="$(echo "$PROMPT" | awk '{for(i=1;i<=NF;i++) if ($i=="resume") {print $(i+1); exit}}')"
  if [ -n "$TARGET" ] && [ -d "$RUNS_DIR/$TARGET" ]; then
    echo "$TARGET" > "$ACTIVE_FILE"
    echo "RAOS Scaffold: active run set to $TARGET (resumed)" >&2
  fi
  exit 0
fi

# 2. /raos kill <run_id>
if echo "$PROMPT" | grep -qE '^/raos[[:space:]]+kill[[:space:]]+[A-Za-z0-9._-]+'; then
  TARGET="$(echo "$PROMPT" | awk '{for(i=1;i<=NF;i++) if ($i=="kill") {print $(i+1); exit}}')"
  if [ -n "$TARGET" ] && [ -d "$RUNS_DIR/$TARGET" ]; then
    date -u +"%Y-%m-%dT%H:%M:%SZ user kill" > "$RUNS_DIR/$TARGET/KILL"
    echo "RAOS Scaffold: KILL sentinel dropped for run $TARGET" >&2
  fi
  exit 0
fi

# 3. Banner for active run
if [ -f "$ACTIVE_FILE" ]; then
  ACTIVE_RUN_ID="$(head -n 1 "$ACTIVE_FILE" | tr -d '[:space:]')"
  RUN_DIR="$RUNS_DIR/$ACTIVE_RUN_ID"
  MANIFEST="$RUN_DIR/manifest.yaml"
  if [ -f "$MANIFEST" ]; then
    PHASE="$(grep -E '^current_phase:' "$MANIFEST" | head -n 1 | awk '{print $2}' | tr -d '"[:space:]')"
    STATUS="$(grep -E '^status:' "$MANIFEST" | head -n 1 | awk '{print $2}' | tr -d '"[:space:]')"
    echo "RAOS Scaffold: active run=$ACTIVE_RUN_ID phase=$PHASE status=$STATUS manifest=$MANIFEST" >&2
  fi
fi

exit 0
