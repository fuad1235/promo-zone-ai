#!/usr/bin/env bash
set -euo pipefail

API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8000}"
ITERATIONS="${ITERATIONS:-40}"

HEALTH_URL="$API_BASE_URL/api/health"
READY_URL="$API_BASE_URL/api/ready"
CAMPAIGNS_URL="$API_BASE_URL/api/campaigns"

ok=0
fail=0
times_file="$(mktemp)"

echo "[load-smoke] base: $API_BASE_URL"
echo "[load-smoke] iterations: $ITERATIONS"

for ((i=1; i<=ITERATIONS; i++)); do
  for url in "$HEALTH_URL" "$READY_URL" "$CAMPAIGNS_URL"; do
    out="$(curl -sS -o /dev/null -w "%{http_code} %{time_total}" "$url" || echo "000 9.999")"
    code="$(awk '{print $1}' <<<"$out")"
    total="$(awk '{print $2}' <<<"$out")"
    echo "$total" >> "$times_file"

    if [[ "$code" =~ ^2 ]]; then
      ok=$((ok + 1))
    else
      fail=$((fail + 1))
      echo "[load-smoke][warn] $url -> HTTP $code"
    fi
  done
done

count="$(wc -l < "$times_file" | tr -d ' ')"
avg="$(awk '{sum+=$1} END {if (NR==0) print "0.000"; else printf "%.3f", sum/NR}' "$times_file")"
p95_index=$(( (count * 95 + 99) / 100 ))
if [[ "$p95_index" -lt 1 ]]; then p95_index=1; fi
p95="$(sort -n "$times_file" | sed -n "${p95_index}p")"
summary="count=$count avg=$avg p95=${p95:-0.000}"

rm -f "$times_file"

echo "[load-smoke] success=$ok failure=$fail $summary"
if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
