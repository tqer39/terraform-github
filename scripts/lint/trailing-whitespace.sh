#!/usr/bin/env bash
# Remove trailing whitespace from text files. Modifies in place.
set -euo pipefail

for f in "$@"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  grep -qE '[[:blank:]]+$' "$f" || continue
  temporary_file="$(mktemp "${f}.XXXXXX")"
  cp -p "$f" "$temporary_file"
  sed -E 's/[[:blank:]]+$//' "$f" >"$temporary_file"
  mv -f "$temporary_file" "$f"
done
