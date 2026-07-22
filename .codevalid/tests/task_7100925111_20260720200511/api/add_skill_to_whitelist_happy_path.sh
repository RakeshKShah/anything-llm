#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TEST_ID="add_skill_to_whitelist_happy_path"
AUTH_TOKEN="${AUTH_TOKEN:-valid-token}"
SKILL_NAME="web-browsing-${CASE_SUFFIX}"

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

echo "STEP: Given — prepare authenticated whitelist add request"
echo "PREREQ: using bearer token and unique skill name ${SKILL_NAME}; assumes server accepts AUTH_TOKEN in this environment"
echo "REQUEST_HEADERS: Authorization: Bearer ${AUTH_TOKEN}"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$REQUEST_BODY_FILE")"

echo "STEP: When — POST /api/agent-skills/whitelist/add"
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

echo "STEP: Then — assert success response"
[ "$code" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${code}"; exit 1; }
grep -F '"success":true' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain success true"; exit 1; }

echo "STEP: Cleanup — no public cleanup endpoint is available for whitelist entries"
echo "Cleanup skipped: repository call graph exposes no DELETE endpoint for whitelist removal"

echo "CODEVALID_TEST_ASSERTION_OK:add_skill_to_whitelist_happy_path"
