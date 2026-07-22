#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TEST_ID="validation_empty_prompt_string"
BODY_FILE="/tmp/${TEST_ID}_body_${CASE_SUFFIX}.txt"
HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$BODY_FILE" "$HEADERS_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

printf '{"prompt":""}' > "$REQUEST_BODY_FILE"

echo "STEP: Given — prepare invalid request body with empty prompt string"

echo "STEP: When — POST empty-string prompt to /api/v1/prompt"
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

echo "STEP: Then — assert falsy empty prompt is rejected"
[ "$code" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${code}"; exit 1; }
grep -F '"error":"prompt is required"' "$BODY_FILE" >/dev/null || { echo 'ASSERTION_FAILED: expected error prompt is required'; exit 1; }

echo "STEP: Cleanup — no stateless cleanup required"
echo "CODEVALID_TEST_ASSERTION_OK:validation_empty_prompt_string"
