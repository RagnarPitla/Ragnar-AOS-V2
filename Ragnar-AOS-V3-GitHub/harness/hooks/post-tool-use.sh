#!/usr/bin/env bash
# RAOS V2 Scaffold — PostToolUse hook
# Responsibilities:
#   1. Append a span to trace.ndjson for the active run
#   2. Increment budgets.tool_calls.used in manifest.yaml (observability only)
#   3. Circuit breaker: detect 3 consecutive failures of the same tool and
#      flip manifest status to "paused" so team-lead surfaces to user on the
#      next turn.

set -u

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
RUNS_DIR="$PROJECT_ROOT/.agentic-os/runs"
ACTIVE_FILE="$RUNS_DIR/.active"

[ -f "$ACTIVE_FILE" ] || exit 0

ACTIVE_RUN_ID="$(head -n 1 "$ACTIVE_FILE" 2>/dev/null | tr -d '[:space:]')"
RUN_DIR="$RUNS_DIR/$ACTIVE_RUN_ID"
[ -d "$RUN_DIR" ] || exit 0

TRACE="$RUN_DIR/trace.ndjson"
MANIFEST="$RUN_DIR/manifest.yaml"

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
TOOL="${TOOL_NAME:-unknown}"
EXIT_CODE="${TOOL_EXIT_CODE:-0}"
DURATION_MS="${TOOL_DURATION_MS:-0}"
ARGS_HASH="$(printf '%s' "${TOOL_INPUT:-}" | cksum | awk '{print $1}')"

# 1. Append NDJSON span (single line; no embedded newlines in args_hash)
printf '{"ts":"%s","tool":"%s","args_hash":"%s","duration_ms":%s,"exit_code":%s}\n' \
  "$TS" "$TOOL" "$ARGS_HASH" "$DURATION_MS" "$EXIT_CODE" >> "$TRACE"

# 2. Increment tool_calls counter in manifest (observability)
if [ -f "$MANIFEST" ]; then
  "$(dirname "$0")/../bin/manifest.sh" incr "$MANIFEST" "budgets.tool_calls.used" 1 2>/dev/null || true
  "$(dirname "$0")/../bin/manifest.sh" set "$MANIFEST" "updated_at" "$TS" 2>/dev/null || true
fi

# 3. Circuit breaker: 3 consecutive failures of the same tool
if [ "$EXIT_CODE" != "0" ]; then
  # Look at the last 3 entries in trace.ndjson; if all failed and same tool, pause.
  LAST3="$(tail -n 3 "$TRACE" 2>/dev/null)"
  if [ "$(echo "$LAST3" | wc -l | tr -d '[:space:]')" = "3" ]; then
    ALL_SAME_TOOL="$(echo "$LAST3" | grep -c "\"tool\":\"$TOOL\"" | tr -d '[:space:]')"
    ALL_FAILED="$(echo "$LAST3" | grep -cE '"exit_code":[1-9]' | tr -d '[:space:]')"
    if [ "$ALL_SAME_TOOL" = "3" ] && [ "$ALL_FAILED" = "3" ]; then
      "$(dirname "$0")/../bin/manifest.sh" set "$MANIFEST" "status" "paused" 2>/dev/null || true
      printf '{"ts":"%s","kind":"circuit_breaker","tool":"%s","note":"3 consecutive failures, run paused"}\n' \
        "$TS" "$TOOL" >> "$TRACE"
    fi
  fi
fi

exit 0
