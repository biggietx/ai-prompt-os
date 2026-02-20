#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROMPTS_DIR="$REPO_ROOT/prompts"
FAIL_COUNT=0

REQUIRED_KEYS=(
  "prompt_id"
  "name"
  "phase"
  "maps_to_gate"
  "version"
  "owner"
  "last_updated_utc"
  "stop_conditions"
  "constitution_alignment"
)

echo "=== Prompt OS Lint ==="
echo ""

# Find all prompt markdown files
PROMPT_FILES=()
while IFS= read -r f; do
  PROMPT_FILES+=("$f")
done < <(find "$PROMPTS_DIR" -name '*.md' -type f | sort)

if [ ${#PROMPT_FILES[@]} -eq 0 ]; then
  echo "[FAIL] No prompt files found under $PROMPTS_DIR"
  exit 1
fi

echo "Found ${#PROMPT_FILES[@]} prompt file(s) to validate."
echo ""

for file in "${PROMPT_FILES[@]}"; do
  rel_path="${file#$REPO_ROOT/}"
  echo "--- Checking: $rel_path ---"

  # 1. YAML header check
  first_line=$(head -n 1 "$file")
  if [ "$first_line" != "---" ]; then
    echo "  [FAIL] Missing YAML header opening '---' on line 1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    # Find closing ---
    closing_line=$(tail -n +2 "$file" | grep -n '^---$' | head -n 1 | cut -d: -f1)
    if [ -z "$closing_line" ]; then
      echo "  [FAIL] Missing YAML header closing '---'"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    else
      echo "  [PASS] YAML header delimiters present"

      # Extract YAML block for key checks (between first --- and closing ---)
      yaml_block=$(sed -n "2,$((closing_line + 1))p" "$file")

      # 2. Required keys check
      for key in "${REQUIRED_KEYS[@]}"; do
        if ! echo "$yaml_block" | grep -q "^${key}:"; then
          echo "  [FAIL] Missing required key: $key"
          FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
      done
      echo "  [PASS] Required YAML keys verified"
    fi
  fi

  # 3. Secret pattern check
  secret_found=0
  if grep -qiE 'sk-[a-zA-Z0-9]{4,}' "$file"; then
    echo "  [FAIL] Potential secret detected: sk- pattern"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    secret_found=1
  fi
  if grep -qiE 'gho_[a-zA-Z0-9]{4,}' "$file"; then
    echo "  [FAIL] Potential secret detected: gho_ pattern"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    secret_found=1
  fi
  if grep -qiE '(apikey|api_key)=.+' "$file"; then
    echo "  [FAIL] Potential secret detected: apikey/api_key= pattern"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    secret_found=1
  fi
  if grep -qiE 'password=.+' "$file"; then
    echo "  [FAIL] Potential secret detected: password= pattern"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    secret_found=1
  fi
  if grep -qiE 'token=.+' "$file"; then
    echo "  [FAIL] Potential secret detected: token= pattern"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    secret_found=1
  fi
  if [ $secret_found -eq 0 ]; then
    echo "  [PASS] No secret patterns detected"
  fi

  # 4. Absolute path check
  path_found=0
  if grep -q '/Users/' "$file"; then
    echo "  [FAIL] Absolute path detected: /Users/"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    path_found=1
  fi
  if grep -qE 'C:\\Users\\' "$file"; then
    echo "  [FAIL] Absolute path detected: C:\\Users\\"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    path_found=1
  fi
  if [ $path_found -eq 0 ]; then
    echo "  [PASS] No absolute paths detected"
  fi

  echo ""
done

echo "=== Summary ==="
if [ $FAIL_COUNT -eq 0 ]; then
  echo "[PASS] All checks passed (${#PROMPT_FILES[@]} files validated)"
  exit 0
else
  echo "[FAIL] $FAIL_COUNT issue(s) found"
  exit 1
fi
