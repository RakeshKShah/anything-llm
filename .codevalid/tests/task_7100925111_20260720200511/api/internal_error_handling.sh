#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TEST_ID="internal_error_handling"
AUTH_TOKEN="${AUTH_TOKEN:-valid-token}"
SKILL_NAME="file-manager-${CASE_SUFFIX}"
FORCE_ERROR_HEADER_NAME="X-Codevalid-Force-Error"
FORCE_ERROR_HEADER_VALUE="agent-skill-whitelist-add"

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

echo "STEP: Given — prepare request intended to exercise internal error handling"
echo "PREREQ: assumes the environment is configured to translate ${FORCE_ERROR_HEADER_NAME}: ${FORCE_ERROR_HEADER_VALUE} into a thrown AgentSkillWhitelist.add error"
echo "REQUEST_HEADERS: Authorization: Bearer ${AUTH_TOKEN}"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_HEADERS: ${FORCE_ERROR_HEADER_NAME}: ${FORCE_ERROR_HEADER_VALUE}"
echo "REQUEST_BODY: $(cat "$REQUEST_BODY_FILE")"

echo "STEP: When — POST /api/agent-skills/whitelist/add for forced internal error"
code="$(curl -sS \
  -D "$HEADERS_FILE" \
  -o "$BODY_FILE" \
  -w '%{http_code}' \
  -X POST \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "${FORCE_ERROR_HEADER_NAME}: ${FORCE_ERROR_HEADER_VALUE}" \
  --data @"$REQUEST_BODY_FILE" \
  "$BASE_URL/api/agent-skills/whitelist/add")"

echo "RESPONSE_HEADERS:"
cat "$HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$BODY_FILE"
echo "RESPONSE_STATUS: $code"

echo "STEP: Then — assert internal server error response"
[ "$code" = "500" ] || { echo "ASSERTION_FAILED: expected HTTP 500 got ${code}"; exit 1; }
grep -F '"success":false' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain success false"; exit 1; }
grep -F 'Database connection failed' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected error message Database connection failed"; exit 1; }

echo "STEP: Cleanup — no durable side effect should remain after failed request"
echo "Cleanup skipped: failed request should not persist a partial whitelist entry"

echo "CODEVALID_TEST_ASSERTION_OK:internal_error_handling"
