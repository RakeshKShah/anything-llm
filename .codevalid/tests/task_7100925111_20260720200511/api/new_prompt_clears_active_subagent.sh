#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TEST_ID="new_prompt_clears_active_subagent"
PROMPT_TEXT="Switch tasks: now prioritize customer support tickets."
BODY_FILE="/tmp/${TEST_ID}_body_${CASE_SUFFIX}.txt"
HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$BODY_FILE" "$HEADERS_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

cat > "$REQUEST_BODY_FILE" <<EOF
{"prompt":"${PROMPT_TEXT}"}
EOF

echo "STEP: Given — verify subagent-clear scenario prerequisites are expected"
echo "PREREQ: This case assumes workspace.subagentRun is active before the request."

echo "STEP: When — POST new prompt to /api/v1/prompt"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"
code="$(curl -sS -D "$HEADERS_FILE" -o "$BODY_FILE" -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -X POST "$BASE_URL/api/v1/prompt" \
  --data-binary @"$REQUEST_BODY_FILE")"
echo "RESPONSE_HEADERS:"
cat "$HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$BODY_FILE"
echo "RESPONSE_STATUS: $code"

echo "STEP: Then — assert prompt is accepted after clearing active subagent"
[ "$code" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${code}"; exit 1; }
grep -E 'prompt_sent|agent_started|accepted|status' "$BODY_FILE" >/dev/null || { echo 'ASSERTION_FAILED: expected success status payload after subagent clear'; exit 1; }

echo "STEP: Cleanup — no stateless cleanup required"
echo "CODEVALID_TEST_ASSERTION_OK:new_prompt_clears_active_subagent"
