#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

RESPONSE_HEADERS="/tmp/create_files_agent_module_load_error_headers_${CASE_SUFFIX}.txt"
RESPONSE_BODY="/tmp/create_files_agent_module_load_error_body_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$RESPONSE_HEADERS" "$RESPONSE_BODY"
}
trap cleanup_files EXIT

# Given
echo "STEP: Given — prepare authenticated request for create-files module load failure case"
echo "PREREQ: caller supplies valid authentication arguments in CURL_AUTH_ARGS and environment is configured so loading the create-files module fails"
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
echo "STEP: Then — assert 500 with available false and non-empty error field"
[ "$code" = "500" ] || { echo "ASSERTION_FAILED: expected HTTP 500 got ${code}"; exit 1; }
grep -F '"available":false' "$RESPONSE_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected body to contain \"available\":false"; exit 1; }
grep -F '"error"' "$RESPONSE_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected body to contain error field"; exit 1; }

# Cleanup
echo "STEP: Cleanup — no stateful setup to remove"

echo "CODEVALID_TEST_ASSERTION_OK:create_files_agent_module_load_error"
