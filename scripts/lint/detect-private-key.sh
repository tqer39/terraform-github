#!/usr/bin/env bash
# Detect private key headers (PEM / OpenSSH).
set -euo pipefail

exit_code=0
pattern='-----BEGIN [A-Z ]*PRIVATE KEY-----'
for f in "$@"; do
  [[ -f "$f" ]] || continue
  if grep -En -e "$pattern" "$f" >/dev/null 2>&1; then
    printf '%s: private key detected\n' "$f" >&2
    exit_code=1
  fi
done
exit "$exit_code"
