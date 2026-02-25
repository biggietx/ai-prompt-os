#!/usr/bin/env bash
set -euo pipefail

# PAS Stack Compiler
#
# Compiles a PAS stack into a single concatenated prompt text.
#
# Resolution rules:
#   1. inherits: Recursively resolve parent stacks depth-first. Parent modules
#      are prepended before the current stack's includes. Cycle detection aborts
#      with exit 1. Max depth: 10.
#   2. includes: Ordered list of module IDs. Each module's content is emitted in
#      the order listed.
#   3. overrides: If a stack lists module IDs in "overrides", those IDs from
#      inherited stacks are replaced by the version in the current stack's
#      includes. The override is by module ID — if the current stack includes a
#      module whose ID also appears in an inherited stack, and that ID is listed
#      in overrides, the inherited copy is dropped.
#
# Deterministic ordering:
#   Modules are emitted in resolution order: inherited (depth-first, left-to-right)
#   then current stack's includes. Within each level, the stack's includes array
#   order is preserved. Duplicates (same module ID appearing from inheritance and
#   includes) are deduplicated: the LAST occurrence wins (current stack takes
#   priority over inherited).
#
# Output format:
#   ### MODULE <id> (<category> <dewey>)
#   <content>
#   (blank line between modules)

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PAS_DIR="$REPO_ROOT/pas"
MODULES_DIR="$PAS_DIR/modules"
STACKS_DIR="$PAS_DIR/stacks"

STACK_ID=""
OUT_FILE=""

# --- Argument parsing ---

usage() {
  echo "Usage: pas_compile.sh --stack <stack_id> [--out <file>]"
  echo ""
  echo "Compiles a PAS stack into concatenated prompt text."
  echo "If --out is omitted, output is written to stdout."
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --stack)
      STACK_ID="$2"
      shift 2
      ;;
    --out)
      OUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "[FAIL] Unknown argument: $1"
      usage
      ;;
  esac
done

if [ -z "$STACK_ID" ]; then
  # No stack requested — check if any stacks exist
  STACK_FILES=$(find "$STACKS_DIR" -name '*.json' -type f 2>/dev/null | sort)
  if [ -z "$STACK_FILES" ]; then
    echo "[INFO] No stacks found — nothing to compile."
    exit 0
  fi
  usage
fi

# --- Dependency: jq ---

if ! command -v jq > /dev/null 2>&1; then
  echo "[FAIL] jq is required for PAS compilation."
  exit 1
fi

# --- Helpers ---

# Find a stack JSON file by stack ID
find_stack_file() {
  local sid="$1"
  local found=""
  for sfile in $(find "$STACKS_DIR" -name '*.json' -type f 2>/dev/null | sort); do
    local fid
    fid=$(jq -r '.id' "$sfile" 2>/dev/null)
    if [ "$fid" = "$sid" ]; then
      found="$sfile"
      break
    fi
  done
  echo "$found"
}

# Find a module JSON file by module ID
find_module_file() {
  local mid="$1"
  local found=""
  for mfile in $(find "$MODULES_DIR" -name '*.json' -type f 2>/dev/null | sort); do
    local fid
    fid=$(jq -r '.id' "$mfile" 2>/dev/null)
    if [ "$fid" = "$mid" ]; then
      found="$mfile"
      break
    fi
  done
  echo "$found"
}

# Resolve a stack into an ordered list of module IDs.
# Arguments: stack_id, depth, visited_stack_ids (colon-separated)
# Output: one module ID per line, in resolution order (inherited first, then includes).
#         Overrides are applied: if current stack lists overrides, those IDs from
#         inherited stacks are dropped.
resolve_stack() {
  local sid="$1"
  local depth="$2"
  local visited="$3"

  # Cycle detection
  if echo ":${visited}:" | grep -q ":${sid}:"; then
    echo "[FAIL] Cycle detected: stack '$sid' already in resolution chain: $visited" >&2
    exit 1
  fi

  # Depth limit
  if [ "$depth" -gt 10 ]; then
    echo "[FAIL] Inheritance depth exceeded (max 10) at stack '$sid'." >&2
    exit 1
  fi

  local sfile
  sfile=$(find_stack_file "$sid")
  if [ -z "$sfile" ]; then
    echo "[FAIL] Stack '$sid' not found." >&2
    exit 1
  fi

  local new_visited="${visited}:${sid}"

  # Collect inherited module IDs (depth-first, left-to-right)
  local inherited_modules=""
  local inherits
  inherits=$(jq -r '.inherits // [] | .[]' "$sfile" 2>/dev/null)
  for parent_sid in $inherits; do
    local parent_modules
    parent_modules=$(resolve_stack "$parent_sid" "$((depth + 1))" "$new_visited") || exit 1
    inherited_modules="${inherited_modules}${inherited_modules:+
}${parent_modules}"
  done

  # Current stack's includes
  local current_modules
  current_modules=$(jq -r '.includes[]' "$sfile" 2>/dev/null)

  # Overrides: drop these IDs from inherited modules
  local overrides
  overrides=$(jq -r '.overrides // [] | .[]' "$sfile" 2>/dev/null)

  # Filter inherited modules: remove overridden IDs
  local filtered_inherited=""
  if [ -n "$inherited_modules" ]; then
    while IFS= read -r mid; do
      local is_overridden=0
      for oid in $overrides; do
        if [ "$mid" = "$oid" ]; then
          is_overridden=1
          break
        fi
      done
      if [ $is_overridden -eq 0 ]; then
        filtered_inherited="${filtered_inherited}${filtered_inherited:+
}${mid}"
      fi
    done <<< "$inherited_modules"
  fi

  # Combine: inherited (filtered) then current
  local all_modules="${filtered_inherited}${filtered_inherited:+
}${current_modules}"

  # Deduplicate: last occurrence wins (reverse, unique, reverse back)
  echo "$all_modules" | awk 'NF' | awk '{a[NR]=$0} END{for(i=NR;i>=1;i--) if(!seen[a[i]]++){b[++j]=a[i]} for(i=j;i>=1;i--) print b[i]}'
}

# --- Main ---

echo "=== PAS Stack Compiler ===" >&2
echo "" >&2
echo "Stack: $STACK_ID" >&2
echo "" >&2

# Resolve module list
MODULE_LIST=$(resolve_stack "$STACK_ID" 0 "") || exit 1

if [ -z "$MODULE_LIST" ]; then
  echo "[FAIL] No modules resolved for stack '$STACK_ID'." >&2
  exit 1
fi

echo "--- Resolved modules ---" >&2
echo "$MODULE_LIST" | while IFS= read -r mid; do
  echo "  $mid" >&2
done
echo "" >&2

# Validate all modules exist
while IFS= read -r mid; do
  mfile=$(find_module_file "$mid")
  if [ -z "$mfile" ]; then
    echo "[FAIL] Module '$mid' not found." >&2
    exit 1
  fi
done <<< "$MODULE_LIST"

# Compile output
OUTPUT=""
FIRST=1
while IFS= read -r mid; do
  mfile=$(find_module_file "$mid")
  category=$(jq -r '.category' "$mfile")
  dewey=$(jq -r '.dewey' "$mfile")
  content=$(jq -r '.content' "$mfile")

  if [ $FIRST -eq 1 ]; then
    FIRST=0
  else
    OUTPUT="${OUTPUT}

"
  fi
  OUTPUT="${OUTPUT}### MODULE ${mid} (${category} ${dewey})
${content}"
done <<< "$MODULE_LIST"

# Write output
if [ -n "$OUT_FILE" ]; then
  echo "$OUTPUT" > "$OUT_FILE"
  echo "[PASS] Compiled ${STACK_ID} → ${OUT_FILE}" >&2
else
  echo "$OUTPUT"
  echo "" >&2
  echo "[PASS] Compiled ${STACK_ID} to stdout." >&2
fi
