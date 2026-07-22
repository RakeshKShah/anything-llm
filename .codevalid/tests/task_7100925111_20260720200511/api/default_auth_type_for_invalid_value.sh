#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
AUTH_HEADER="${AUTH_HEADER:-Authorization: Bearer test-admin-token}"
TEST_ID="default_auth_type_for_invalid_value"
HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"
BODY_FILE="/tmp/${TEST_ID}_body_${CASE_SUFFIX}.txt"
REQ_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$HEADERS_FILE" "$BODY_FILE" "$REQ_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQ_BODY_FILE" <<'JSON'
{"clientId":"default-client-123","clientSecret":"default-secret-456","authType":"invalid-type-xyz"}
JSON

# Given
echo "STEP: Given — prepare request payload with invalid authType"
echo "PREREQ: using authenticated admin request header for defaulting behavior"

# When
echo "STEP: When — POST Outlook auth-url with invalid authType"
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
echo "STEP: Then — assert invalid authType is handled successfully"
[ "$code" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${code}"; exit 1; }
grep -F '"success":true' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected success true in response body"; exit 1; }
if command -v jq >/dev/null 2>&1; then
  jq -e '(.url // .authUrl // .authorizationUrl // .data.url // .data.authUrl // .data.authorizationUrl) | type == "string" and length > 0' "$BODY_FILE" >/dev/null 2>&1 \
    || { echo "ASSERTION_FAILED: expected non-empty auth URL field in JSON response"; exit 1; }
else
  grep -E 'https?://' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected URL-like content in response body"; exit 1; }
fi

echo "CODEVALID_TEST_ASSERTION_OK:default_auth_type_for_invalid_value"
