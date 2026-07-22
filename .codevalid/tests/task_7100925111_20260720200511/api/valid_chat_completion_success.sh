#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
API_KEY="${API_KEY:-sk-test-key-12345}"
BODY_FILE="/tmp/valid_chat_completion_success_body_${CASE_SUFFIX}.txt"
HEADERS_FILE="/tmp/valid_chat_completion_success_headers_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/valid_chat_completion_success_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$BODY_FILE" "$HEADERS_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<'JSON'
{"model":"my-workspace","messages":[{"role":"system","content":"You are a helpful assistant"},{"role":"user","content":"What is AnythingLLM?"}],"stream":false,"temperature":0.7}
JSON

# Given — bring the system to the required state
echo "STEP: Given — prepare valid workspace chat completion request"
echo "PREREQ: using valid API key and existing workspace slug my-workspace"
echo "REQUEST_HEADERS: Authorization: Bearer [REDACTED]"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"

# When — perform the action under test
echo "STEP: When — submit valid chat completion request"
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
echo "STEP: Then — assert successful completion payload is returned"
[ "$code" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${code}"; exit 1; }
grep -F '"id"' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain id"; exit 1; }
grep -F '"textResponse"' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain textResponse"; exit 1; }
grep -F '"sources"' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain sources"; exit 1; }
grep -F '"close"' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response body to contain close"; exit 1; }
if grep -F '"error"' "$BODY_FILE" >/dev/null; then
  echo "ASSERTION_FAILED: did not expect error field in successful response"
  exit 1
fi

# Cleanup — undo Given side effects
echo "STEP: Cleanup — no cleanup required for stateless API request"

echo "CODEVALID_TEST_ASSERTION_OK:valid_chat_completion_success"
