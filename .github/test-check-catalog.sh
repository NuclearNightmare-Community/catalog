#!/usr/bin/env bash
# Self-test for check-catalog.sh: builds fixtures in a temp folder and asserts the exit code and,
# for failures, that the output names the offending file. Exit 0 when every case passes.
set -euo pipefail
check="$(cd -- "$(dirname -- "$0")" && pwd)/check-catalog.sh"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
failed=0

valid() { # a valid base set in $1
  printf '{}' > "$1/index.json"; printf 's' > "$1/index.json.minisig"
  printf '{}' > "$1/revoked.json"; printf 's' > "$1/revoked.json.minisig"
}
expect() { # expect <case> <exit> <text or ""> ; fixture already built in $tmp/<case>
  local name=$1 want=$2 text=$3 out rc
  set +e; out=$(bash "$check" "$tmp/$name" 2>&1); rc=$?; set -e
  if [ "$rc" -ne "$want" ]; then
    echo "FAIL $name: exit $rc, expected $want"; echo "$out"; failed=1
  elif [ -n "$text" ] && ! grep -qF -- "$text" <<< "$out"; then
    echo "FAIL $name: output doesn't name $text"; echo "$out"; failed=1
  else
    echo "PASS $name (exit $rc)"
  fi
}
case_dir() { mkdir -p "$tmp/$1"; echo "$tmp/$1"; }

d=$(case_dir json-without-minisig); valid "$d"; rm "$d/revoked.json.minisig"
expect json-without-minisig 1 "revoked.json has no revoked.json.minisig"

d=$(case_dir minisig-without-json); valid "$d"; printf 's' > "$d/keys.json.minisig"
expect minisig-without-json 1 "keys.json.minisig has no keys.json"

d=$(case_dir missing-index-pair); valid "$d"; rm "$d/index.json" "$d/index.json.minisig"
expect missing-index-pair 1 "index.json is missing"

d=$(case_dir json-over-limit); valid "$d"; head -c 4194305 /dev/zero > "$d/index.json"
expect json-over-limit 1 "index.json is 4194305 bytes"

d=$(case_dir minisig-over-limit); valid "$d"; head -c 4097 /dev/zero > "$d/revoked.json.minisig"
expect minisig-over-limit 1 "revoked.json.minisig is 4097 bytes"

d=$(case_dir symlink); valid "$d"; printf '{}' > "$d/target.json"; rm "$d/revoked.json"
ln -s target.json "$d/revoked.json" 2>/dev/null || true
if [ -L "$d/revoked.json" ]; then
  expect symlink 1 "revoked.json is not a regular file"
else
  echo "FAIL symlink: this system cannot create a symlink (on Git Bash set MSYS=winsymlinks:nativestrict)"; failed=1
fi

d=$(case_dir valid-at-limits); valid "$d"
head -c 4194304 /dev/zero > "$d/index.json"; head -c 4096 /dev/zero > "$d/index.json.minisig"
printf '{}' > "$d/keys.json"; printf 's' > "$d/keys.json.minisig"; printf 'x' > "$d/README.md"
expect valid-at-limits 0 ""

if [ "$failed" -ne 0 ]; then echo "self-test: failed"; exit 1; fi
echo "self-test: passed"
