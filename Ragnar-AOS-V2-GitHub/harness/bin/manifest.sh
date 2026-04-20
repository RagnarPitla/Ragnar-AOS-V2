#!/usr/bin/env bash
# RAOS V2 Scaffold — manifest.sh
# Zero-dependency YAML helper for the run manifest. No jq, no yq. Just awk/sed.
# Scope: small, flat-ish YAML with known keys. Not a general YAML parser.
#
# Usage:
#   manifest.sh init      <run_id> <objective_id> <objective_statement> <os_name> [runtime]
#   manifest.sh get       <manifest_path> <dotted.key>
#   manifest.sh set       <manifest_path> <dotted.key> <value>
#   manifest.sh incr      <manifest_path> <dotted.key> <amount>
#   manifest.sh append-checkpoint <manifest_path> <ts> <phase> <note>
#   manifest.sh append-gate       <manifest_path> <ts> <kind> <bucket> <decision> <note>
#
# Supported keys (flat enough for sed-targeting):
#   run_id, os_name, objective_id, objective_statement, runtime,
#   created_at, updated_at, status, current_phase,
#   budgets.enforce,
#   budgets.tool_calls.{soft,hard,used},
#   budgets.wall_clock_s.{soft,hard,used},
#   budgets.dollars.{soft,hard,used},
#   trace_file, verification_file, costs_file, linked_tasks_version

set -u

cmd="${1:-}"
shift || true

_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

_init() {
  local run_id="$1" obj_id="$2" stmt="$3" os_name="$4" runtime="${5:-claude-code}"
  local ts; ts="$(_now)"
  # Escape a quote in the statement for YAML double-quoted scalar
  local stmt_esc; stmt_esc="$(printf '%s' "$stmt" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  cat <<EOF
# RAOS V2 Scaffold run manifest
run_id: "$run_id"
os_name: "$os_name"
objective_id: "$obj_id"
objective_statement: "$stmt_esc"
runtime: "$runtime"
created_at: "$ts"
updated_at: "$ts"
status: "accepted"
current_phase: "research"
budgets:
  enforce: false
  tool_calls:   { soft: 150, hard: 300, used: 0 }
  wall_clock_s: { soft: 1800, hard: 7200, used: 0 }
  dollars:      { soft: 5.00, hard: 20.00, used: 0.00 }
checkpoints: []
gates: []
trace_file: "trace.ndjson"
verification_file: "verification.yaml"
costs_file: "costs.json"
linked_tasks_version: 0
EOF
}

# _set_scalar <file> <key> <value>   — top-level scalar (e.g., status, current_phase)
_set_scalar() {
  local file="$1" key="$2" val="$3"
  if grep -qE "^$key:" "$file"; then
    # macOS and GNU sed both accept -i with an empty backup using this form
    awk -v k="$key" -v v="$val" '
      BEGIN { replaced=0 }
      {
        if (!replaced && $0 ~ "^" k ":") {
          printf "%s: \"%s\"\n", k, v
          replaced=1
        } else { print }
      }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  else
    printf '%s: "%s"\n' "$key" "$val" >> "$file"
  fi
}

# _set_inline_kv <file> <parent_key> <child_key> <value>
# Updates "used: N" inside a one-line YAML dict like:
#   tool_calls:   { soft: 150, hard: 300, used: 0 }
_set_inline_kv() {
  local file="$1" parent="$2" child="$3" val="$4"
  awk -v parent="$parent" -v child="$child" -v val="$val" '
    {
      if ($0 ~ parent ":" && $0 ~ "{") {
        # Replace "child: <n>" inside the line with "child: <val>"
        re = child ": [0-9.]+"
        sub(re, child ": " val)
      }
      print
    }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

_incr_inline_kv() {
  local file="$1" parent="$2" child="$3" amount="$4"
  # Pull current value
  local cur
  cur="$(awk -v parent="$parent" -v child="$child" '
    $0 ~ parent ":" && $0 ~ "{" {
      match($0, child ": [0-9.]+")
      s = substr($0, RSTART, RLENGTH)
      sub(child ": ", "", s)
      print s
      exit
    }
  ' "$file")"
  [ -z "$cur" ] && cur="0"
  local new
  new="$(awk -v a="$cur" -v b="$amount" 'BEGIN { printf (a+b) }')"
  _set_inline_kv "$file" "$parent" "$child" "$new"
}

case "$cmd" in
  init)
    _init "$@"
    ;;
  set)
    file="$1"; key="$2"; val="$3"
    case "$key" in
      budgets.enforce|status|current_phase|updated_at|run_id|os_name|objective_id|runtime|trace_file|verification_file|costs_file|linked_tasks_version)
        _set_scalar "$file" "${key##*.}" "$val"
        ;;
      budgets.tool_calls.*|budgets.wall_clock_s.*|budgets.dollars.*)
        parent="$(echo "$key" | awk -F. '{print $2}')"
        child="$(echo "$key" | awk -F. '{print $3}')"
        _set_inline_kv "$file" "$parent" "$child" "$val"
        ;;
      *)
        echo "manifest.sh: unsupported key for set: $key" >&2
        exit 1
        ;;
    esac
    ;;
  get)
    file="$1"; key="$2"
    case "$key" in
      budgets.tool_calls.*|budgets.wall_clock_s.*|budgets.dollars.*)
        parent="$(echo "$key" | awk -F. '{print $2}')"
        child="$(echo "$key" | awk -F. '{print $3}')"
        awk -v parent="$parent" -v child="$child" '
          $0 ~ parent ":" && $0 ~ "{" {
            match($0, child ": [0-9.]+")
            s = substr($0, RSTART, RLENGTH)
            sub(child ": ", "", s)
            print s
            exit
          }
        ' "$file"
        ;;
      *)
        grep -E "^${key##*.}:" "$file" | head -n 1 | sed -E 's/^[^:]+:\s*"?([^"]*)"?$/\1/'
        ;;
    esac
    ;;
  incr)
    file="$1"; key="$2"; amount="$3"
    case "$key" in
      budgets.tool_calls.*|budgets.wall_clock_s.*|budgets.dollars.*)
        parent="$(echo "$key" | awk -F. '{print $2}')"
        child="$(echo "$key" | awk -F. '{print $3}')"
        _incr_inline_kv "$file" "$parent" "$child" "$amount"
        ;;
      *)
        echo "manifest.sh: incr only supports budget keys" >&2
        exit 1
        ;;
    esac
    ;;
  append-checkpoint)
    file="$1"; ts="$2"; phase="$3"; note="${4:-}"
    # Append to checkpoints: [] — rewrite the line to a block form on first use.
    awk -v entry="  - { ts: \"$ts\", phase: \"$phase\", note: \"$note\" }" '
      /^checkpoints: \[\]/ { print "checkpoints:"; print entry; done=1; next }
      /^checkpoints:\s*$/  { print; print entry; done=1; next }
      { print }
      END { if (!done) print entry }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    ;;
  append-gate)
    file="$1"; ts="$2"; kind="$3"; bucket="$4"; decision="$5"; note="${6:-}"
    awk -v entry="  - { ts: \"$ts\", kind: \"$kind\", bucket: \"$bucket\", decision: \"$decision\", note: \"$note\" }" '
      /^gates: \[\]/ { print "gates:"; print entry; done=1; next }
      /^gates:\s*$/  { print; print entry; done=1; next }
      { print }
      END { if (!done) print entry }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    ;;
  *)
    echo "manifest.sh: unknown command '$cmd'" >&2
    echo "commands: init|get|set|incr|append-checkpoint|append-gate" >&2
    exit 1
    ;;
esac
