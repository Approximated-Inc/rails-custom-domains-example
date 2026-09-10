#!/usr/bin/env sh
set -eu

port="${PORT:-3086}"
base="http://127.0.0.1:${port}"
control_host="${CONTROL_HOST:-localhost}"
body_file="$(mktemp)"
headers_file="$(mktemp)"
trap 'rm -f "$body_file" "$headers_file"' EXIT

request() {
  host="$1"
  expected_status="$2"
  expected_text="$3"
  status="$(curl --silent --show-error --output "$body_file" --dump-header "$headers_file" --write-out '%{http_code}' --header "Host: ${host}" "$base/")"
  test "$status" = "$expected_status"
  if test -n "$expected_text"; then
    grep -F "$expected_text" "$body_file" >/dev/null
  fi
}

request atlas.test 200 'Atlas Press'
request juniper.test 200 'Juniper Journal'
request unknown.test 404 ''
request "$control_host" 302 ''

printf '%s\n' 'Smoke passed: two tenants, unknown-host 404, and protected control host.'
