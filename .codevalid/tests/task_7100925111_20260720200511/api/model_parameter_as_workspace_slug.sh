#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
API_KEY="${API_KEY:-sk-test-key-12345}"
BODY_FILE="/tmp/model_parameter_as_workspace_slug_body_${CASE_SUFFIX}.txt"
HEADERS_FILE="/tmp/model_parameter_as_workspace_slug_headers_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/model_parameter_as_workspace_slug_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$BODY_FILE" "$HEADERS_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<'JSON'
{"model":"finance-assistant","messages":[{"role":"user","content":"What documents are available?"}],"stream":false}
JSON

# Given — bring the system to the required state
echo "STEP: Given — prepare request that uses model parameter as workspace slug"
echo "PREREQ: using valid API key and existing workspace slug finance-assistant"
echo "REQUEST_HEADERS: Authorization: Bearer [REDACTED]"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"

# When — perform the action under test
echo "STEP: When — submit chat completion request with finance-assistant as model"
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
echo "STEP: Then — assert model field is accepted as workspace slug"
[ "$code" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${code}"; exit 1; }
grep -F '"textResponse"' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected textResponse in response body"; exit 1; }
grep -F '"sources"' "$BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected sources in response body"; exit 1; }

# Cleanup — undo Given side effects
echo "STEP: Cleanup — no cleanup required for stateless API request"

echo "CODEVALID_TEST_ASSERTION_OK:model_parameter_as_workspace_slug"
