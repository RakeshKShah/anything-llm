#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TEST_ID="happy_path_hypervisor_running_prompt_sent"
PROMPT_TEXT="Summarize the latest sales report and draft an email to the team."
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

echo "STEP: Given — verify prompt endpoint is reachable for a hypervisor-running happy-path attempt"
echo "PREREQ: This case assumes the environment has an active workspace with piRpc and OpenAI configured; if not, the endpoint may legitimately return a different status."

echo "STEP: When — POST prompt to /api/v1/prompt"
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

echo "STEP: Then — assert success response for forwarded prompt when hypervisor is active"
[ "$code" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${code}"; exit 1; }
grep -F '"status":"prompt_sent"' "$BODY_FILE" >/dev/null || { echo 'ASSERTION_FAILED: expected response body to contain status prompt_sent'; exit 1; }
grep -F '"workspace_id"' "$BODY_FILE" >/dev/null || { echo 'ASSERTION_FAILED: expected response body to contain workspace_id'; exit 1; }

echo "STEP: Cleanup — no stateless cleanup required"
echo "CODEVALID_TEST_ASSERTION_OK:happy_path_hypervisor_running_prompt_sent"
