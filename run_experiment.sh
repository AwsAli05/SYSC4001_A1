#!/usr/bin/env bash
set -euo pipefail

TRACE="trace.txt"
VECTOR="vector_table.txt"
DEVICE="device_table.txt"
OUTFILE="results.csv"

# Sweep ranges → 5 × 12 = 60 runs
CONTEXT_TIMES=(5 10 15 20 30)                     # context save times (ms)
ISR_BODIES=(40 60 80 100 120 140 160 180 200 220 240 260)   # ISR body times (ms)

# Build your binary once
./build.sh

# CSV header
echo "context_ms,isr_body_ms,total_time_ms" > "$OUTFILE"

for ctx in "${CONTEXT_TIMES[@]}"; do
  for body in "${ISR_BODIES[@]}"; do
    echo "Running CTX_SAVE_MS=$ctx  ISR_BODY_MS=$body"
    CTX_SAVE_MS="$ctx" ISR_BODY_MS="$body" \
      ./bin/interrupts "$TRACE" "$VECTOR" "$DEVICE" >/dev/null

    # Calculate total time = last_start + last_duration
    total=$(awk -F',' 'NF>=2{
      gsub(/^[ \t]+|[ \t]+$/, "", $1);
      gsub(/^[ \t]+|[ \t]+$/, "", $2);
      s=$1+0; d=$2+0
    } END{print s+d}' execution.txt)

    echo "$ctx,$body,$total" >> "$OUTFILE"
  done
done

echo "✅ 60 simulations complete. Results saved to $OUTFILE"
