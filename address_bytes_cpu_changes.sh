#!/usr/bin/env bash
set -euo pipefail

TRACE="trace.txt"
VECTOR="vector_table.txt"
DEVICE="device_table.txt"

# keep the same base kernel settings you used in Part 2
CTX=10
ISR=80

OUT_ADDR="results_addr_width.csv"
OUT_CPU="results_cpu_speed.csv"

./build.sh

echo "addr_bytes,total_time_ms" > "$OUT_ADDR"
for BYTES in 2 4; do
  CTX_SAVE_MS=$CTX ISR_BODY_MS=$ISR ADDR_BYTES=$BYTES CPU_SPEEDUP=1 \
    ./bin/interrupts "$TRACE" "$VECTOR" "$DEVICE" >/dev/null
  total=$(awk -F',' 'NF>=2{gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $2); s=$1+0; d=$2+0} END{print s+d}' execution.txt)
  echo "$BYTES,$total" >> "$OUT_ADDR"
done

echo "cpu_speedup,total_time_ms" > "$OUT_CPU"
for SPEED in 1 2 4; do
  CTX_SAVE_MS=$CTX ISR_BODY_MS=$ISR ADDR_BYTES=2 CPU_SPEEDUP=$SPEED \
    ./bin/interrupts "$TRACE" "$VECTOR" "$DEVICE" >/dev/null
  total=$(awk -F',' 'NF>=2{gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $2); s=$1+0; d=$2+0} END{print s+d}' execution.txt)
  echo "$SPEED,$total" >> "$OUT_CPU"
done

echo "✅ What-if simulations complete:"
echo "  - Address width results -> $OUT_ADDR"
echo "  - CPU speed results     -> $OUT_CPU"
