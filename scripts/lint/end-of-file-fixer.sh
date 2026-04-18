#!/usr/bin/env bash
# Ensure each text file ends with exactly one newline. Modifies in place.
set -euo pipefail

for f in "$@"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  if [[ -n "$(tail -c 1 "$f")" ]]; then
    printf '\n' >>"$f"
  fi
done
