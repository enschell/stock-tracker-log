#!/bin/bash
set -uo pipefail

TICKERS=(${TICKERS:-TSLA MU AMD})
OUTDIR="${1:-data/raw}"
FUNCS=(OVERVIEW TIME_SERIES_DAILY)

mkdir -p "$OUTDIR"

is_bad() {
  local f="$1"
  [ -s "$f" ] || return 0
  grep -q '"Note"\|"Information"\|"Error Message"' "$f" 2>/dev/null && return 0
  return 1
}

fetch() {
  local T="$1" FN="$2" OUT="$3" URL
  if [ "$FN" == "TIME_SERIES_DAILY" ]; then
    URL="https://www.alphavantage.co/query?function=${FN}&symbol=${T}&outputsize=compact&apikey=${ALPHAVANTAGE_API_KEY}"
  else
    URL="https://www.alphavantage.co/query?function=${FN}&symbol=${T}&apikey=${ALPHAVANTAGE_API_KEY}"
  fi
  curl -s "$URL" -o "$OUT"
}

first=1
for T in "${TICKERS[@]}"; do
  for FN in "${FUNCS[@]}"; do
    [ $first -eq 0 ] && sleep 15
    first=0
    OUT="$OUTDIR/${T}_${FN}.json"
    fetch "$T" "$FN" "$OUT"
    if is_bad "$OUT"; then
      sleep 20
      fetch "$T" "$FN" "$OUT"
      is_bad "$OUT" && echo "FAILED $T $FN" >&2
    fi
  done
done
