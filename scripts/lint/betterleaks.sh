#!/usr/bin/env bash
# Scan only the selected tracked files; never scan local credentials or caches.
set -euo pipefail

if [[ $# -eq 0 ]]; then
    exit 0
fi
scan_dir="$(mktemp -d)"
trap 'rm -rf "$scan_dir"' EXIT
for file in "$@"; do
    if [[ "${BETTERLEAKS_ALL_FILES:-false}" == "true" ]]; then
        [[ -f "$file" ]] || continue
        mkdir -p "$scan_dir/$(dirname "$file")"
        cp "$file" "$scan_dir/$file"
    else
        git cat-file -e ":$file" 2>/dev/null || continue
        mkdir -p "$scan_dir/$(dirname "$file")"
        # Read the index so partially staged secrets cannot escape detection.
        git show ":$file" > "$scan_dir/$file"
    fi
done
betterleaks dir --no-banner --redact --exit-code 1 --validation=false "$scan_dir"
