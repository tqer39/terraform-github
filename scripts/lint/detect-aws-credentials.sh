#!/usr/bin/env bash
# Detect AWS Access Key IDs in staged files.
# cspell:ignore AKIA ASIA
# --allow-missing-credentials: kept for compatibility; we do not read ~/.aws.
set -euo pipefail

files=()
for arg in "$@"; do
  case "$arg" in
    --allow-missing-credentials) ;;
    *) files+=("$arg") ;;
  esac
done

exit_code=0
pattern='(AKIA|ASIA)[0-9A-Z]{16}'
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  if grep -En "$pattern" "$f" >/dev/null 2>&1; then
    printf '%s: possible AWS Access Key ID\n' "$f" >&2
    grep -En "$pattern" "$f" >&2 || true
    exit_code=1
  fi
done
exit "$exit_code"
