#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TEST_ID="add_skill_failure_due_to_duplicate_or_constraint"
AUTH_TOKEN="${AUTH_TOKEN:-valid-token}"
SKILL_NAME="email-sender"

HEADERS1_FILE="/tmp/${TEST_ID}_headers1_${CASE_SUFFIX}.txt"
BODY1_FILE="/tmp/${TEST_ID}_body1_${CASE_SUFFIX}.txt"
HEADERS2_FILE="/tmp/${TEST_ID}_headers2_${CASE_SUFFIX}.txt"
BODY2_FILE="/tmp/${TEST_ID}_body2_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$HEADERS1_FILE" "$BODY1_FILE" "$HEADERS2_FILE" "$BODY2_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<EOF
{"skillName":"${SKILL_NAME}"}
EOF

echo "STEP: Given — seed potential duplicate by attempting initial whitelist add"
echo "PREREQ: using bearer token; if the skill already exists this setup may itself return 400, which still establishes duplicate-state intent"
echo "REQUEST_HEADERS: Authorization: Bearer ${AUTH_TOKEN}"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$REQUEST_BODY_FILE")"
first_code="$(curl -sS \
  -D "$HEADERS1_FILE" \
  -o "$BODY1_FILE" \
  -w '%{http_code}' \
  -X POST \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  --data @"$REQUEST_BODY_FILE" \
  "$BASE_URL/api/agent-skills/whitelist/add")"

echo "RESPONSE_HEADERS:"
cat "$HEADERS1_FILE"
echo "RESPONSE_BODY:"
cat "$BODY1_FILE"
echo "RESPONSE_STATUS: $first_code"
[ "$first_code" = "200" ] || [ "$first_code" = "400" ] || { echo "ASSERTION_FAILED: expected setup HTTP 200 or 400 got ${first_code}"; exit 1; }

echo "STEP: When — POST duplicate whitelist add request"
code="$(curl -sS \
  -D "$HEADERS2_FILE" \
  -o "$BODY2_FILE" \
  -w '%{http_code}' \
  -X POST \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  --data @"$REQUEST_BODY_FILE" \
  "$BASE_URL/api/agent-skills/whitelist/add")"

echo "RESPONSE_HEADERS:"
cat "$HEADERS2_FILE"
echo "RESPONSE_BODY:"
cat "$BODY2_FILE"
echo "RESPONSE_STATUS: $code"

echo "STEP: Then — assert duplicate or constraint failure response"
[ "$code" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${code}"; exit 1; }
grep -F '"success":false' "$BODY2_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain success false"; exit 1; }
grep -F 'error' "$BODY2_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain an error field"; exit 1; }

echo "STEP: Cleanup — no public cleanup endpoint is available for whitelist entries"
echo "Cleanup skipped: repository call graph exposes no DELETE endpoint for whitelist removal"

echo "CODEVALID_TEST_ASSERTION_OK:add_skill_failure_due_to_duplicate_or_constraint"
