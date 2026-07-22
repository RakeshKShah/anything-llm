#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
INVALID_API_KEY="${INVALID_API_KEY:-sk-invalid-key}"
BODY_FILE="/tmp/invalid_api_key_rejected_body_${CASE_SUFFIX}.txt"
HEADERS_FILE="/tmp/invalid_api_key_rejected_headers_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/invalid_api_key_rejected_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$BODY_FILE" "$HEADERS_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<'JSON'
{"model":"my-workspace","messages":[{"role":"user","content":"Test"}]}
JSON

# Given — bring the system to the required state
echo "STEP: Given — prepare request with invalid API key"
echo "PREREQ: using intentionally invalid API key"
echo "REQUEST_HEADERS: Authorization: Bearer [REDACTED INVALID]"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"

# When — perform the action under test
echo "STEP: When — submit chat completion request with invalid API key"
echo "REQUEST_HEADERS: Authorization: Bearer [REDACTED INVALID]"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"
code="$(curl -sS -D "$HEADERS_FILE" -o "$BODY_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/v1/openai/chat/completions" \
  -H "Authorization: Bearer $INVALID_API_KEY" \
  -H 'Content-Type: application/json' \
  --data @"$REQUEST_BODY_FILE")"
echo "RESPONSE_HEADERS:"
cat "$HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$BODY_FILE"
echo "RESPONSE_STATUS: $code"

# Then — HTTP/body assertions
echo "STEP: Then — assert invalid API key is rejected"
[ "$code" = "403" ] || { echo "ASSERTION_FAILED: expected HTTP 403 got ${code}"; exit 1; }
if ! grep -E 'Invalid|invalid|API key|api key|Forbidden|forbidden|error' "$BODY_FILE" >/dev/null; then
  echo "ASSERTION_FAILED: expected invalid API key error details in response body"
  exit 1
fi

# Cleanup — undo Given side effects
echo "STEP: Cleanup — no cleanup required for rejected request"

echo "CODEVALID_TEST_ASSERTION_OK:invalid_api_key_rejected"
