#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

RESPONSE_HEADERS="/tmp/create_files_agent_unauthenticated_access_rejected_headers_${CASE_SUFFIX}.txt"
RESPONSE_BODY="/tmp/create_files_agent_unauthenticated_access_rejected_body_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$RESPONSE_HEADERS" "$RESPONSE_BODY"
}
trap cleanup_files EXIT

# Given
echo "STEP: Given — ensure request is sent without authentication"
echo "PREREQ: do not provide any authentication headers so validatedRequest middleware can reject the request"

# When
echo "STEP: When — call GET /api/agent-skills/create-files-agent/is-available without credentials"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
code="$(curl -sS -H 'Accept: application/json' -D "$RESPONSE_HEADERS" -o "$RESPONSE_BODY" -w '%{http_code}' "$BASE_URL/api/agent-skills/create-files-agent/is-available")"
echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY"
echo
echo "RESPONSE_STATUS: $code"

# Then
echo "STEP: Then — assert unauthenticated request is rejected"
if [ "$code" != "401" ] && [ "$code" != "403" ]; then
  echo "ASSERTION_FAILED: expected HTTP 401 or 403 got ${code}"
  exit 1
fi
[ -s "$RESPONSE_BODY" ] || { echo "ASSERTION_FAILED: expected non-empty rejection response body"; exit 1; }

# Cleanup
echo "STEP: Cleanup — no stateful setup to remove"

echo "CODEVALID_TEST_ASSERTION_OK:create_files_agent_unauthenticated_access_rejected"
