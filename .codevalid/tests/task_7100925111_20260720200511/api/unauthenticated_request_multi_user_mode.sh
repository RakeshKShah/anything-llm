#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TEST_ID="unauthenticated_request_multi_user_mode"
SKILL_NAME="data-lookup-${CASE_SUFFIX}"

HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"
BODY_FILE="/tmp/${TEST_ID}_body_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$HEADERS_FILE" "$BODY_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<EOF
{"skillName":"${SKILL_NAME}"}
EOF

echo "STEP: Given — prepare unauthenticated request for multi-user mode"
echo "PREREQ: assumes app is running in multi-user mode for this test environment"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$REQUEST_BODY_FILE")"

echo "STEP: When — POST /api/agent-skills/whitelist/add without Authorization header"
code="$(curl -sS \
  -D "$HEADERS_FILE" \
  -o "$BODY_FILE" \
  -w '%{http_code}' \
  -X POST \
  -H "Content-Type: application/json" \
  --data @"$REQUEST_BODY_FILE" \
  "$BASE_URL/api/agent-skills/whitelist/add")"

echo "RESPONSE_HEADERS:"
cat "$HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$BODY_FILE"
echo "RESPONSE_STATUS: $code"

echo "STEP: Then — assert unauthorized response"
[ "$code" = "401" ] || { echo "ASSERTION_FAILED: expected HTTP 401 got ${code}"; exit 1; }
grep -F '"success":false' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain success false"; exit 1; }
grep -F 'Unauthorized' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected error message Unauthorized"; exit 1; }

echo "STEP: Cleanup — no side effects expected for unauthorized request"
echo "Cleanup skipped: unauthorized request should not persist any whitelist entry"

echo "CODEVALID_TEST_ASSERTION_OK:unauthenticated_request_multi_user_mode"
