#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
API_KEY="${API_KEY:-sk-test-key-12345}"
BODY_FILE="/tmp/streaming_chat_completion_success_body_${CASE_SUFFIX}.txt"
HEADERS_FILE="/tmp/streaming_chat_completion_success_headers_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/streaming_chat_completion_success_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$BODY_FILE" "$HEADERS_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<'JSON'
{"model":"stream-workspace","messages":[{"role":"user","content":"Summarize the document"}],"stream":true}
JSON

# Given — bring the system to the required state
echo "STEP: Given — prepare streaming chat completion request"
echo "PREREQ: using valid API key and existing workspace slug stream-workspace"
echo "REQUEST_HEADERS: Authorization: Bearer [REDACTED]"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_HEADERS: Accept: text/event-stream"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"

# When — perform the action under test
echo "STEP: When — submit streaming chat completion request"
echo "REQUEST_HEADERS: Authorization: Bearer [REDACTED]"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_HEADERS: Accept: text/event-stream"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"
code="$(curl -sS -N -D "$HEADERS_FILE" -o "$BODY_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/v1/openai/chat/completions" \
  -H "Authorization: Bearer $API_KEY" \
  -H 'Content-Type: application/json' \
  -H 'Accept: text/event-stream' \
  --data @"$REQUEST_BODY_FILE")"
echo "RESPONSE_HEADERS:"
cat "$HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$BODY_FILE"
echo "RESPONSE_STATUS: $code"

# Then — HTTP/body assertions
echo "STEP: Then — assert streaming response is returned"
[ "$code" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${code}"; exit 1; }
[ -s "$BODY_FILE" ] || { echo "ASSERTION_FAILED: expected non-empty streaming response body"; exit 1; }
if ! grep -i 'content-type:' "$HEADERS_FILE" >/dev/null; then
  echo "ASSERTION_FAILED: expected content-type header in response"
  exit 1
fi
if ! grep -E 'data:|textResponse|close' "$BODY_FILE" >/dev/null; then
  echo "ASSERTION_FAILED: expected streaming chunks or completion markers in body"
  exit 1
fi

# Cleanup — undo Given side effects
echo "STEP: Cleanup — no cleanup required for stateless API request"

echo "CODEVALID_TEST_ASSERTION_OK:streaming_chat_completion_success"
