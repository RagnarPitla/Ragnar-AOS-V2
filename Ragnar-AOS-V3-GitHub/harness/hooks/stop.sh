#!/usr/bin/env bash
# RAOS V2 Scaffold — Stop hook
# Responsibilities:
#   1. Write a checkpoint.json snapshot (phase, tasks.json version, last trace line)
#   2. Update manifest.yaml updated_at
#   3. Run costs.sh to roll up cost estimates from trace.ndjson

set -u

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
RUNS_DIR="$PROJECT_ROOT/.agentic-os/runs"
ACTIVE_FILE="$RUNS_DIR/.active"

[ -f "$ACTIVE_FILE" ] || exit 0

ACTIVE_RUN_ID="$(head -n 1 "$ACTIVE_FILE" 2>/dev/null | tr -d '[:space:]')"
RUN_DIR="$RUNS_DIR/$ACTIVE_RUN_ID"
[ -d "$RUN_DIR" ] || exit 0

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
MANIFEST="$RUN_DIR/manifest.yaml"
CHECKPOINT="$RUN_DIR/checkpoint.json"
TRACE="$RUN_DIR/trace.ndjson"
TASKS_JSON="$PROJECT_ROOT/.github/tasks.json"

# 1. Read current phase from manifest (best-effort)
PHASE="$(grep -E '^current_phase:' "$MANIFEST" 2>/dev/null | head -n 1 | awk '{print $2}' | tr -d '"[:space:]')"
[ -z "$PHASE" ] && PHASE="unknown"

TASKS_VERSION="$(grep -E '"version"' "$TASKS_JSON" 2>/dev/null | head -n 1 | awk -F'[:,]' '{print $2}' | tr -d '[:space:]')"
[ -z "$TASKS_VERSION" ] && TASKS_VERSION="0"

LAST_SPAN="$(tail -n 1 "$TRACE" 2>/dev/null | tr -d '\n' | sed 's/"/\\"/g')"

# 2. Write checkpoint (overwrites — latest snapshot wins; history is in manifest.checkpoints[])
cat > "$CHECKPOINT" <<EOF
{
  "ts": "$TS",
  "run_id": "$ACTIVE_RUN_ID",
  "phase": "$PHASE",
  "tasks_version": $TASKS_VERSION,
  "last_span": "$LAST_SPAN"
}
EOF

# 3. Append a checkpoint entry to manifest.checkpoints (observability; newest last)
"$(dirname "$0")/../bin/manifest.sh" append-checkpoint "$MANIFEST" "$TS" "$PHASE" "auto-on-stop" 2>/dev/null || true
"$(dirname "$0")/../bin/manifest.sh" set "$MANIFEST" "updated_at" "$TS" 2>/dev/null || true

# 4. Roll up cost estimates
"$(dirname "$0")/../bin/costs.sh" "$RUN_DIR" 2>/dev/null || true

exit 0
