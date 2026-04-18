#!/usr/bin/env bash
# Fail if any staged file exceeds --max-kb (default 512).
set -euo pipefail

max_kb=512
files=()
for arg in "$@"; do
  case "$arg" in
    --max-kb=*) max_kb="${arg#--max-kb=}" ;;
    *) files+=("$arg") ;;
  esac
done

exit_code=0
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  size_bytes=$(wc -c <"$f")
  size_kb=$(( size_bytes / 1024 ))
  if (( size_kb > max_kb )); then
    printf '%s: %d KB (exceeds %d KB)\n' "$f" "$size_kb" "$max_kb" >&2
    exit_code=1
  fi
done
exit "$exit_code"
