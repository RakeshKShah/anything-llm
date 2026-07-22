#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TEST_ID="missing_skillname_bad_request"
AUTH_TOKEN="${AUTH_TOKEN:-valid-token}"

HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"
BODY_FILE="/tmp/${TEST_ID}_body_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$HEADERS_FILE" "$BODY_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<EOF
{}
EOF

echo "STEP: Given — prepare authenticated request missing required skillName"
echo "PREREQ: using bearer token with empty JSON body to exercise validation"
echo "REQUEST_HEADERS: Authorization: Bearer ${AUTH_TOKEN}"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$REQUEST_BODY_FILE")"

echo "STEP: When — POST /api/agent-skills/whitelist/add without skillName"
code="$(curl -sS \
  -D "$HEADERS_FILE" \
  -o "$BODY_FILE" \
  -w '%{http_code}' \
  -X POST \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  --data @"$REQUEST_BODY_FILE" \
  "$BASE_URL/api/agent-skills/whitelist/add")"

echo "RESPONSE_HEADERS:"
cat "$HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$BODY_FILE"
echo "RESPONSE_STATUS: $code"

echo "STEP: Then — assert bad request validation error"
[ "$code" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${code}"; exit 1; }
grep -F '"success":false' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain success false"; exit 1; }
grep -F 'Missing skillName' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected error message Missing skillName"; exit 1; }

echo "STEP: Cleanup — stateless validation case"
echo "Cleanup skipped: request should not create any whitelist entry"

echo "CODEVALID_TEST_ASSERTION_OK:missing_skillname_bad_request"
