#!/usr/bin/env bash
# Remove trailing whitespace from text files. Modifies in place.
set -euo pipefail

for f in "$@"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  sed -E 's/[[:space:]]+$//' "$f" >"$f.tmp"
  cat "$f.tmp" >"$f"
  rm -f "$f.tmp"
done
