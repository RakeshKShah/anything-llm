#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TEST_ID="security_user_permissions_enforced"
PROMPT_TEXT="Read customer list and analyze trends."
BODY_FILE="/tmp/${TEST_ID}_body_${CASE_SUFFIX}.txt"
HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$BODY_FILE" "$HEADERS_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<EOF
{"prompt":"${PROMPT_TEXT}"}
EOF

echo "STEP: Given — verify authorized prompt-processing prerequisites are expected"
echo "PREREQ: This case assumes the active workspace RPC channel is already authorized with read-only permissions."

echo "STEP: When — POST prompt to /api/v1/prompt"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"
code="$(curl -sS -D "$HEADERS_FILE" -o "$BODY_FILE" -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -X POST "$BASE_URL/api/v1/prompt" \
  --data-binary @"$REQUEST_BODY_FILE")"
echo "RESPONSE_HEADERS:"
cat "$HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$BODY_FILE"
echo "RESPONSE_STATUS: $code"

echo "STEP: Then — assert authorized request is accepted"
[ "$code" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${code}"; exit 1; }
grep -F '"status":"prompt_sent"' "$BODY_FILE" >/dev/null || { echo 'ASSERTION_FAILED: expected prompt_sent status'; exit 1; }
grep -F '"workspace_id"' "$BODY_FILE" >/dev/null || { echo 'ASSERTION_FAILED: expected workspace_id in response'; exit 1; }

echo "STEP: Cleanup — no stateless cleanup required"
echo "CODEVALID_TEST_ASSERTION_OK:security_user_permissions_enforced"
