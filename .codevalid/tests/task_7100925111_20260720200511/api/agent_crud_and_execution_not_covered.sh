#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

RESPONSE_HEADERS_FILE="/tmp/agent_crud_and_execution_not_covered_response_headers_${CASE_SUFFIX}.txt"
RESPONSE_BODY_FILE="/tmp/agent_crud_and_execution_not_covered_response_body_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/agent_crud_and_execution_not_covered_request_body_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$RESPONSE_HEADERS_FILE" "$RESPONSE_BODY_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

printf '{}\n' > "$REQUEST_BODY_FILE"

# Given
echo "STEP: Given — document the public API coverage available in the call graph"
echo "PREREQ: The call graph exposes POST /api/review but no dedicated agent CRUD or execution endpoints"

# When
echo "STEP: When — call POST /api/review to confirm it is unrelated to agent CRUD and execution acceptance criteria"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"
RESPONSE_STATUS="$(curl -sS -D "$RESPONSE_HEADERS_FILE" -o "$RESPONSE_BODY_FILE" -w '%{http_code}' \
  -X POST \
  -H 'Content-Type: application/json' \
  --data @"$REQUEST_BODY_FILE" \
  "$BASE_URL/api/review")"
echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY_FILE"
echo "RESPONSE_STATUS: $RESPONSE_STATUS"

# Then
echo "STEP: Then — assert the endpoint responds and document the acceptance-criteria gap"
[ "$RESPONSE_STATUS" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${RESPONSE_STATUS}"; exit 1; }
grep -F '"status":"review_triggered"' "$RESPONSE_BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain status review_triggered"; exit 1; }
echo "PREREQ: Autonomous AI agent creation, configuration, persistence, permissions, and workflow execution require dedicated public endpoints not present in the provided call graph"

# Cleanup
echo "STEP: Cleanup — no persistent side effects to remove"

echo "CODEVALID_TEST_ASSERTION_OK:agent_crud_and_execution_not_covered"
