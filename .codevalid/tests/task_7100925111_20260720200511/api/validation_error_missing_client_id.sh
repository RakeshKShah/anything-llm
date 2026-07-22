#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
AUTH_HEADER="${AUTH_HEADER:-Authorization: Bearer test-admin-token}"
TEST_ID="validation_error_missing_client_id"
HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"
BODY_FILE="/tmp/${TEST_ID}_body_${CASE_SUFFIX}.txt"
REQ_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$HEADERS_FILE" "$BODY_FILE" "$REQ_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQ_BODY_FILE" <<'JSON'
{"clientSecret":"secret-only","authType":"common"}
JSON

# Given
echo "STEP: Given — prepare request payload missing clientId"
echo "PREREQ: using authenticated admin request header for validation path"

# When
echo "STEP: When — POST Outlook auth-url without clientId"
echo "REQUEST_HEADERS:"
printf '%s\nContent-Type: application/json\n' "$AUTH_HEADER"
echo "REQUEST_BODY:"
cat "$REQ_BODY_FILE"
code="$({ curl -sS -D "$HEADERS_FILE" -o "$BODY_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/admin/agent-skills/outlook/auth-url" \
  -H "$AUTH_HEADER" \
  -H 'Content-Type: application/json' \
  --data @"$REQ_BODY_FILE"; } || true)"
echo "RESPONSE_HEADERS:"
cat "$HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$BODY_FILE"
echo "RESPONSE_STATUS: $code"

# Then
echo "STEP: Then — assert 400 validation error for missing clientId"
[ "$code" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${code}"; exit 1; }
grep -F '"success":false' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected success false in response body"; exit 1; }
grep -F 'Client ID and Client Secret are required.' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected missing credentials validation message"; exit 1; }

echo "CODEVALID_TEST_ASSERTION_OK:validation_error_missing_client_id"
