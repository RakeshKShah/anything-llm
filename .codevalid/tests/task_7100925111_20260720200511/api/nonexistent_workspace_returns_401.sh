#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
API_KEY="${API_KEY:-sk-test-key-12345}"
BODY_FILE="/tmp/nonexistent_workspace_returns_401_body_${CASE_SUFFIX}.txt"
HEADERS_FILE="/tmp/nonexistent_workspace_returns_401_headers_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/nonexistent_workspace_returns_401_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$BODY_FILE" "$HEADERS_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<'JSON'
{"model":"nonexistent-workspace-xyz","messages":[{"role":"user","content":"Hello"}]}
JSON

# Given — bring the system to the required state
echo "STEP: Given — prepare request referencing non-existent workspace slug"
echo "PREREQ: using valid API key with missing workspace slug nonexistent-workspace-xyz"
echo "REQUEST_HEADERS: Authorization: Bearer [REDACTED]"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"

# When — perform the action under test
echo "STEP: When — submit chat completion request for non-existent workspace"
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
echo "STEP: Then — assert missing workspace returns 401"
[ "$code" = "401" ] || { echo "ASSERTION_FAILED: expected HTTP 401 got ${code}"; exit 1; }
if [ -s "$BODY_FILE" ]; then
  if grep -v '^$' "$BODY_FILE" >/dev/null; then
    echo "ASSERTION_FAILED: expected empty body for response.end() path"
    exit 1
  fi
fi

# Cleanup — undo Given side effects
echo "STEP: Cleanup — no cleanup required for rejected request"

echo "CODEVALID_TEST_ASSERTION_OK:nonexistent_workspace_returns_401"
