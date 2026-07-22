#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TEST_ID="middleware_rejects_unauthenticated_request"
HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"
BODY_FILE="/tmp/${TEST_ID}_body_${CASE_SUFFIX}.txt"
REQ_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$HEADERS_FILE" "$BODY_FILE" "$REQ_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQ_BODY_FILE" <<'JSON'
{"clientId":"no-auth-client","clientSecret":"no-auth-secret","authType":"common"}
JSON

# Given
echo "STEP: Given — prepare unauthenticated request payload"

# When
echo "STEP: When — POST Outlook auth-url without authentication credentials"
echo "REQUEST_HEADERS:"
printf 'Content-Type: application/json\n'
echo "REQUEST_BODY:"
cat "$REQ_BODY_FILE"
code="$({ curl -sS -D "$HEADERS_FILE" -o "$BODY_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/admin/agent-skills/outlook/auth-url" \
  -H 'Content-Type: application/json' \
  --data @"$REQ_BODY_FILE"; } || true)"
echo "RESPONSE_HEADERS:"
cat "$HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$BODY_FILE"
echo "RESPONSE_STATUS: $code"

# Then
echo "STEP: Then — assert middleware rejects unauthenticated access"
case "$code" in
  401|403) ;;
  *) echo "ASSERTION_FAILED: expected HTTP 401 or 403 got ${code}"; exit 1 ;;
esac

echo "CODEVALID_TEST_ASSERTION_OK:middleware_rejects_unauthenticated_request"
