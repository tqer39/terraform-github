#!/usr/bin/env bash
# Validate JSON syntax for each given file (ignores .json5).
set -euo pipefail

exit_code=0
for f in "$@"; do
  [[ -f "$f" ]] || continue
  [[ "$f" == *.json5 ]] && continue
  if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" 2>/dev/null; then
    printf '%s: invalid JSON\n' "$f" >&2
    exit_code=1
  fi
done
exit "$exit_code"
