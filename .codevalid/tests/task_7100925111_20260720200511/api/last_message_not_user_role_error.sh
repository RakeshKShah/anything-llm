#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
API_KEY="${API_KEY:-sk-test-key-12345}"
BODY_FILE="/tmp/last_message_not_user_role_error_body_${CASE_SUFFIX}.txt"
HEADERS_FILE="/tmp/last_message_not_user_role_error_headers_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/last_message_not_user_role_error_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$BODY_FILE" "$HEADERS_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<'JSON'
{"model":"test-workspace","messages":[{"role":"user","content":"Question?"},{"role":"assistant","content":"Answer."}]}
JSON

# Given — bring the system to the required state
echo "STEP: Given — prepare request whose last message role is not user"
echo "PREREQ: using valid API key and existing workspace slug test-workspace"
echo "REQUEST_HEADERS: Authorization: Bearer [REDACTED]"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"

# When — perform the action under test
echo "STEP: When — submit chat completion request with assistant as final message"
echo "REQUEST_HEADERS: Authorization: Bearer [REDACTED]"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"
code="$(curl -sS -D "$HEADERS_FILE" -o "$BODY_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/v1/openai/chat/completions" \
  -H "Authorization: Bearer $API_KEY" \
  -H 'Content-Type: application/json' \
  --data @"$REQUEST_BODY_FILE")"
echo "RESPONSE_HEADERS:"
cat "$HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$BODY_FILE"
echo "RESPONSE_STATUS: $code"

# Then — HTTP/body assertions
echo "STEP: Then — assert validation error explains last message must be user"
[ "$code" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${code}"; exit 1; }
grep -F 'No user prompt found. Must be last element in message array with' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected specific no user prompt found message"; exit 1; }
grep -E '"type"[[:space:]]*:[[:space:]]*"abort"' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected type abort in response body"; exit 1; }
grep -E '"close"[[:space:]]*:[[:space:]]*true' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected close true in response body"; exit 1; }

# Cleanup — undo Given side effects
echo "STEP: Cleanup — no cleanup required for validation failure request"

echo "CODEVALID_TEST_ASSERTION_OK:last_message_not_user_role_error"
