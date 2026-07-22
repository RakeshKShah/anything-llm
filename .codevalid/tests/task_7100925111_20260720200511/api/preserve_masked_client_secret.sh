#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
AUTH_HEADER="${AUTH_HEADER:-Authorization: Bearer test-admin-token}"
TEST_ID="preserve_masked_client_secret"
HEADERS1_FILE="/tmp/${TEST_ID}_headers1_${CASE_SUFFIX}.txt"
BODY1_FILE="/tmp/${TEST_ID}_body1_${CASE_SUFFIX}.txt"
HEADERS2_FILE="/tmp/${TEST_ID}_headers2_${CASE_SUFFIX}.txt"
BODY2_FILE="/tmp/${TEST_ID}_body2_${CASE_SUFFIX}.txt"
REQ1_BODY_FILE="/tmp/${TEST_ID}_request1_${CASE_SUFFIX}.json"
REQ2_BODY_FILE="/tmp/${TEST_ID}_request2_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$HEADERS1_FILE" "$BODY1_FILE" "$HEADERS2_FILE" "$BODY2_FILE" "$REQ1_BODY_FILE" "$REQ2_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQ1_BODY_FILE" <<'JSON'
{"clientId":"seed-secret-client","clientSecret":"existing-secret-value","authType":"common"}
JSON
cat > "$REQ2_BODY_FILE" <<'JSON'
{"clientId":"preserve-client-333","clientSecret":"********","authType":"common"}
JSON

# Given
echo "STEP: Given — create an initial config with a real clientSecret"
echo "PREREQ: seeding baseline secret so masked placeholder can be reused"
echo "REQUEST_HEADERS:"
printf '%s\nContent-Type: application/json\n' "$AUTH_HEADER"
echo "REQUEST_BODY:"
cat "$REQ1_BODY_FILE"
code1="$({ curl -sS -D "$HEADERS1_FILE" -o "$BODY1_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/admin/agent-skills/outlook/auth-url" \
  -H "$AUTH_HEADER" \
  -H 'Content-Type: application/json' \
  --data @"$REQ1_BODY_FILE"; } || true)"
echo "RESPONSE_HEADERS:"
cat "$HEADERS1_FILE"
echo "RESPONSE_BODY:"
cat "$BODY1_FILE"
echo "RESPONSE_STATUS: $code1"
[ "$code1" = "200" ] || { echo "ASSERTION_FAILED: expected Given prereq HTTP 200 got ${code1}"; exit 1; }

# When
echo "STEP: When — POST masked clientSecret placeholder"
echo "REQUEST_HEADERS:"
printf '%s\nContent-Type: application/json\n' "$AUTH_HEADER"
echo "REQUEST_BODY:"
cat "$REQ2_BODY_FILE"
code2="$({ curl -sS -D "$HEADERS2_FILE" -o "$BODY2_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/admin/agent-skills/outlook/auth-url" \
  -H "$AUTH_HEADER" \
  -H 'Content-Type: application/json' \
  --data @"$REQ2_BODY_FILE"; } || true)"
echo "RESPONSE_HEADERS:"
cat "$HEADERS2_FILE"
echo "RESPONSE_BODY:"
cat "$BODY2_FILE"
echo "RESPONSE_STATUS: $code2"

# Then
echo "STEP: Then — assert masked secret is accepted and auth URL returned"
[ "$code2" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${code2}"; exit 1; }
grep -F '"success":true' "$BODY2_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected success true in response body"; exit 1; }
if command -v jq >/dev/null 2>&1; then
  jq -e '(.url // .authUrl // .authorizationUrl // .data.url // .data.authUrl // .data.authorizationUrl) | type == "string" and length > 0' "$BODY2_FILE" >/dev/null 2>&1 \
    || { echo "ASSERTION_FAILED: expected non-empty auth URL field in JSON response"; exit 1; }
else
  grep -E 'https?://' "$BODY2_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected URL-like content in response body"; exit 1; }
fi

echo "CODEVALID_TEST_ASSERTION_OK:preserve_masked_client_secret"
