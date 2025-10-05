#!/usr/bin/env bash
set -euo pipefail

# --- Paths & settings ---
TRACE_DIR="testcases"
VECTOR_FILE="vector_table.txt"
DEVICE_FILE="device_table.txt"

OUT_DIR="runs"
CSV="summary_traces.csv"
CONTEXTS=(10 20 30)

# --- Preconditions ---
if [[ ! -x ./build.sh ]]; then
  echo "build.sh not found or not executable"; exit 1
fi
if [[ ! -d "$TRACE_DIR" ]]; then
  echo "Trace directory '$TRACE_DIR' not found"; exit 1
fi
if [[ ! -f interrupts.cpp ]]; then
  echo "interrupts.cpp not found in current directory"; exit 1
fi
if [[ ! -f "$VECTOR_FILE" || ! -f "$DEVICE_FILE" ]]; then
  echo "vector_table.txt or device_table.txt missing"; exit 1
fi

mkdir -p "$OUT_DIR"
echo "trace,context_ms,total_time_ms" > "$CSV"

# Backup original source once
BACKUP="interrupts.cpp.bak"
cp -f interrupts.cpp "$BACKUP"

# Helper: set CTX_SAVE_MS initializer in interrupts.cpp
set_ctx() {
  local ctx="$1"
  # replace: long long CTX_SAVE_MS  = <number>;
  # keep spacing; only change the number
  sed -E -i "s/^(\s*long long\s+CTX_SAVE_MS\s*=\s*)[0-9]+(\s*;)/\1${ctx}\2/" interrupts.cpp

  # sanity check: confirm file now contains the requested value
  if ! grep -Eq "long long\s+CTX_SAVE_MS\s*=\s*${ctx}\s*;" interrupts.cpp; then
    echo "Failed to set CTX_SAVE_MS to ${ctx} in interrupts.cpp"; exit 1
  fi
}

# Loop contexts and traces
for ctx in "${CONTEXTS[@]}"; do
  echo "=== Building with CTX_SAVE_MS=${ctx} ms ==="
  set_ctx "$ctx"
  ./build.sh

  for trace in "$TRACE_DIR"/*.txt; do
    [[ -e "$trace" ]] || continue
    base=$(basename "$trace" .txt)
    echo "Running: $base  (context=${ctx} ms)"

    ./bin/interrupts "$trace" "$VECTOR_FILE" "$DEVICE_FILE" >/dev/null

    # Move the produced execution.txt to a unique file
    outfile="${OUT_DIR}/${base}__ctx${ctx}.txt"
    mv -f execution.txt "$outfile"

    # total time = last_line_start + last_line_duration
    total=$(awk -F',' '
      NF>=2 {
        # trim spaces on fields 1 & 2
        gsub(/^[ \t]+|[ \t]+$/, "", $1);
        gsub(/^[ \t]+|[ \t]+$/, "", $2);
        s=$1+0; d=$2+0;
      }
      END { print s + d }
    ' "$outfile")

    echo "${base},${ctx},${total}" >> "$CSV"
  done
done

# Restore original source
mv -f "$BACKUP" interrupts.cpp

echo "✅ Done. Traces saved in '$OUT_DIR', summary in '$CSV'."
