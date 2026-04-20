#!/usr/bin/env bash
# RAOS V2 Scaffold — PreToolUse hook
# Responsibilities (in order):
#   1. Kill switch: exit 2 if .agentic-os/runs/<active>/KILL exists
#   2. Auth gate dispatch for pac/az commands when a gate is pending
# Budget enforcement is OFF by default in V2. The manifest tracks usage
# for observability (see post-tool-use.sh), but nothing blocks on it unless
# budgets.enforce: true is set in the run manifest.

set -u

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
RUNS_DIR="$PROJECT_ROOT/.agentic-os/runs"
ACTIVE_FILE="$RUNS_DIR/.active"

# No active run? Nothing to enforce. Let tool calls through.
[ -f "$ACTIVE_FILE" ] || exit 0

ACTIVE_RUN_ID="$(head -n 1 "$ACTIVE_FILE" 2>/dev/null | tr -d '[:space:]')"
RUN_DIR="$RUNS_DIR/$ACTIVE_RUN_ID"
[ -d "$RUN_DIR" ] || exit 0

# 1. Kill switch
if [ -f "$RUN_DIR/KILL" ]; then
  echo "RAOS Scaffold: run $ACTIVE_RUN_ID has a KILL sentinel. Halting tool call." >&2
  echo "To resume, delete $RUN_DIR/KILL and run /raos resume $ACTIVE_RUN_ID" >&2
  exit 2
fi

# 2. Optional budget enforcement (only if user flipped the flag)
MANIFEST="$RUN_DIR/manifest.yaml"
if [ -f "$MANIFEST" ]; then
  ENFORCE="$(grep -E '^\s*enforce:' "$MANIFEST" | head -n 1 | awk '{print $2}' | tr -d '[:space:]')"
  if [ "$ENFORCE" = "true" ]; then
    TC_USED="$(awk '/tool_calls:/{f=1} f && /used:/{print $2; exit}' "$MANIFEST" | tr -d '[:space:]')"
    TC_HARD="$(awk '/tool_calls:/{f=1} f && /hard:/{print $2; exit}' "$MANIFEST" | tr -d '[:space:]')"
    if [ -n "$TC_USED" ] && [ -n "$TC_HARD" ] && [ "$TC_USED" -ge "$TC_HARD" ] 2>/dev/null; then
      echo "RAOS Scaffold: tool_calls hard cap reached ($TC_USED/$TC_HARD) for run $ACTIVE_RUN_ID." >&2
      echo "Raise budgets.tool_calls.hard in $MANIFEST or set enforce: false to continue." >&2
      exit 2
    fi
  fi
fi

# 3. Auth gate dispatch (stub — populated per integration)
# Pattern: if the command matches `pac ` or `az `, check the auth gate state.
# The pac-cli / azure specialists write .agentic-os/runs/<id>/gates/auth-<tool>.pending
# Until the gate file is removed, we block the tool call with a clear message.
if [ -n "${TOOL_INPUT:-}" ]; then
  case "$TOOL_INPUT" in
    *"pac "*)
      if [ -f "$RUN_DIR/gates/auth-pac.pending" ]; then
        echo "RAOS Scaffold: pac-cli auth gate pending. See $RUN_DIR/gates/auth-pac.pending" >&2
        exit 2
      fi
      ;;
    *"az "*)
      if [ -f "$RUN_DIR/gates/auth-az.pending" ]; then
        echo "RAOS Scaffold: Azure auth gate pending. See $RUN_DIR/gates/auth-az.pending" >&2
        exit 2
      fi
      ;;
  esac
fi

exit 0
