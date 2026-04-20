#!/usr/bin/env bash
# RAOS V2 Scaffold — trace-to-sqlite.sh (optional power-user tool)
# Convert trace.ndjson -> trace.sqlite for richer queries.
# Requires sqlite3 in PATH. Skipped silently if not installed.

set -u

RUN_DIR="${1:-}"
[ -z "$RUN_DIR" ] && { echo "trace-to-sqlite.sh: run_dir required" >&2; exit 1; }

command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 not installed. Skip." >&2; exit 0; }

TRACE="$RUN_DIR/trace.ndjson"
DB="$RUN_DIR/trace.sqlite"
[ -f "$TRACE" ] || { echo "No trace.ndjson. Skip." >&2; exit 0; }

rm -f "$DB"
sqlite3 "$DB" <<'SQL'
CREATE TABLE spans (
  ts TEXT,
  tool TEXT,
  args_hash TEXT,
  duration_ms INTEGER,
  exit_code INTEGER
);
SQL

# Parse each NDJSON line with awk and pipe SQL INSERTs to sqlite3.
awk '
{
  ts=""; tool=""; args_hash=""; duration_ms=0; exit_code=0
  if (match($0, /"ts":"[^"]*"/))          { s=substr($0,RSTART,RLENGTH); gsub(/"ts":"|"$/,"",s); ts=s }
  if (match($0, /"tool":"[^"]*"/))        { s=substr($0,RSTART,RLENGTH); gsub(/"tool":"|"$/,"",s); tool=s }
  if (match($0, /"args_hash":"[^"]*"/))   { s=substr($0,RSTART,RLENGTH); gsub(/"args_hash":"|"$/,"",s); args_hash=s }
  if (match($0, /"duration_ms":[0-9]+/))  { s=substr($0,RSTART,RLENGTH); gsub(/"duration_ms":/,"",s); duration_ms=s }
  if (match($0, /"exit_code":[0-9]+/))    { s=substr($0,RSTART,RLENGTH); gsub(/"exit_code":/,"",s); exit_code=s }
  gsub(/'\''/, "''", tool); gsub(/'\''/, "''", args_hash); gsub(/'\''/, "''", ts)
  printf "INSERT INTO spans VALUES ('\''%s'\'', '\''%s'\'', '\''%s'\'', %s, %s);\n", ts, tool, args_hash, duration_ms, exit_code
}
' "$TRACE" | sqlite3 "$DB"

echo "Wrote $DB ($(wc -l < "$TRACE" | tr -d '[:space:]') spans). Try: sqlite3 $DB 'select tool, count(*) from spans group by tool;'" >&2
exit 0
