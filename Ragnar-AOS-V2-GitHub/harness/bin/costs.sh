#!/usr/bin/env bash
# RAOS V2 Scaffold — costs.sh
# Roll up cost estimates from trace.ndjson into costs.json.
# Heuristic only. Claude Code hooks don't expose token counts directly, so we
# estimate from tool counts and durations. Users who care about precise $ numbers
# can wire claude-code telemetry into trace.ndjson later.

set -u

RUN_DIR="${1:-}"
[ -z "$RUN_DIR" ] && { echo "costs.sh: run_dir required" >&2; exit 1; }

TRACE="$RUN_DIR/trace.ndjson"
OUT="$RUN_DIR/costs.json"

[ -f "$TRACE" ] || { echo '{}' > "$OUT"; exit 0; }

TOTAL_SPANS="$(wc -l < "$TRACE" | tr -d '[:space:]')"
FAIL_SPANS="$(grep -cE '"exit_code":[1-9]' "$TRACE" | tr -d '[:space:]')"
TOTAL_DURATION_MS="$(awk -F'"duration_ms":' '{ n=split($2, a, ","); if (n>=1) sum+=a[1] } END { print sum+0 }' "$TRACE")"

BY_TOOL="$(awk -F'"tool":"' '{ split($2, a, "\""); t=a[1]; c[t]++ } END { for (t in c) printf "    \"%s\": %d,\n", t, c[t] }' "$TRACE" | sed '$s/,$//')"

# Dollar estimate: wildly approximate. 300 tool calls ~ $5 on Sonnet, $15 on Opus.
# We expose the multiplier as an env var for tuning.
DOLLARS_PER_100_CALLS="${RAOS_DOLLARS_PER_100_CALLS:-1.67}"
EST_DOLLARS="$(awk -v n="$TOTAL_SPANS" -v r="$DOLLARS_PER_100_CALLS" 'BEGIN { printf "%.2f", (n/100.0)*r }')"

cat > "$OUT" <<EOF
{
  "total_spans": $TOTAL_SPANS,
  "failed_spans": $FAIL_SPANS,
  "total_duration_ms": $TOTAL_DURATION_MS,
  "estimated_dollars": $EST_DOLLARS,
  "by_tool": {
$BY_TOOL
  },
  "note": "Estimates only. Set RAOS_DOLLARS_PER_100_CALLS to tune."
}
EOF

exit 0
