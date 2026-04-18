#!/usr/bin/env bash
# Normalize line endings to LF. --fix=lf is required.
set -euo pipefail

mode=""
files=()
for arg in "$@"; do
  case "$arg" in
    --fix=*) mode="${arg#--fix=}" ;;
    *) files+=("$arg") ;;
  esac
done

if [[ "$mode" != "lf" ]]; then
  echo "mixed-line-ending.sh: only --fix=lf is supported" >&2
  exit 2
fi

for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  if grep -q $'\r' "$f"; then
    tr -d '\r' <"$f" >"$f.tmp"
    cat "$f.tmp" >"$f"
    rm -f "$f.tmp"
  fi
done
