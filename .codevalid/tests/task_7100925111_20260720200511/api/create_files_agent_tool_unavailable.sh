#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

RESPONSE_HEADERS="/tmp/create_files_agent_tool_unavailable_headers_${CASE_SUFFIX}.txt"
RESPONSE_BODY="/tmp/create_files_agent_tool_unavailable_body_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$RESPONSE_HEADERS" "$RESPONSE_BODY"
}
trap cleanup_files EXIT

# Given
echo "STEP: Given — prepare authenticated request for create-files unavailable case"
echo "PREREQ: caller supplies valid authentication arguments in CURL_AUTH_ARGS and environment is configured so the tool reports unavailable"
: "${CURL_AUTH_ARGS:=}"

# When
echo "STEP: When — call GET /api/agent-skills/create-files-agent/is-available"
echo "REQUEST_HEADERS: Accept: application/json ${CURL_AUTH_ARGS}"
echo "REQUEST_BODY: <empty>"
code="$(curl -sS ${CURL_AUTH_ARGS} -H 'Accept: application/json' -D "$RESPONSE_HEADERS" -o "$RESPONSE_BODY" -w '%{http_code}' "$BASE_URL/api/agent-skills/create-files-agent/is-available")"
echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY"
echo
echo "RESPONSE_STATUS: $code"

# Then
echo "STEP: Then — assert 200 and available false without error field"
[ "$code" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${code}"; exit 1; }
grep -F '"available":false' "$RESPONSE_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected body to contain \"available\":false"; exit 1; }
if grep -F '"error"' "$RESPONSE_BODY" >/dev/null; then
  echo "ASSERTION_FAILED: expected no error field when tool is unavailable but not failing"
  exit 1
fi

# Cleanup
echo "STEP: Cleanup — no stateful setup to remove"

echo "CODEVALID_TEST_ASSERTION_OK:create_files_agent_tool_unavailable"
