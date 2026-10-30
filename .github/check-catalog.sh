#!/usr/bin/env bash
# Checks the catalog files in <dir> before anything is published: index.json and its .minisig are
# present, every .json has its .minisig and the reverse, each is a regular file, no .json is over
# 4 MiB and no .minisig over 4096 bytes. Exit 0 when all pass, 1 otherwise (each error names the file).
set -euo pipefail
dir="${1:?usage: check-catalog.sh <dir>}"
cd -- "$dir"
fail=0
err() { echo "::error::$1"; fail=1; }
present() { [ -e "$1" ] || [ -L "$1" ]; }
for f in index.json index.json.minisig; do
  if ! present "$f"; then err "$f is missing (index.json and index.json.minisig are required)"; fi
done
for base in keys index revoked; do
  json="$base.json"
  sig="$base.json.minisig"
  for f in "$json" "$sig"; do
    if present "$f" && { [ -L "$f" ] || [ ! -f "$f" ]; }; then
      err "$f is not a regular file"
    fi
  done
  if present "$json" && ! present "$sig"; then err "$json has no $sig"; fi
  if present "$sig" && ! present "$json"; then err "$sig has no $json"; fi
  if [ -f "$json" ] && [ ! -L "$json" ]; then
    size=$(wc -c < "$json")
    if [ "$size" -gt 4194304 ]; then err "$json is $size bytes, over the 4 MiB (4194304 bytes) limit"; fi
  fi
  if [ -f "$sig" ] && [ ! -L "$sig" ]; then
    size=$(wc -c < "$sig")
    if [ "$size" -gt 4096 ]; then err "$sig is $size bytes, over the 4096-byte limit"; fi
  fi
done
if [ "$fail" -ne 0 ]; then
  echo "catalog check failed; nothing is published"
  exit 1
fi
echo "catalog check passed"
