#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"

REQUEST_BODY_FILE="/tmp/trigger_review_concurrent_requests_request_body_${CASE_SUFFIX}.txt"
RESP1_HEADERS_FILE="/tmp/trigger_review_concurrent_requests_resp1_headers_${CASE_SUFFIX}.txt"
RESP1_BODY_FILE="/tmp/trigger_review_concurrent_requests_resp1_body_${CASE_SUFFIX}.txt"
RESP1_STATUS_FILE="/tmp/trigger_review_concurrent_requests_resp1_status_${CASE_SUFFIX}.txt"
RESP2_HEADERS_FILE="/tmp/trigger_review_concurrent_requests_resp2_headers_${CASE_SUFFIX}.txt"
RESP2_BODY_FILE="/tmp/trigger_review_concurrent_requests_resp2_body_${CASE_SUFFIX}.txt"
RESP2_STATUS_FILE="/tmp/trigger_review_concurrent_requests_resp2_status_${CASE_SUFFIX}.txt"
RESP3_HEADERS_FILE="/tmp/trigger_review_concurrent_requests_resp3_headers_${CASE_SUFFIX}.txt"
RESP3_BODY_FILE="/tmp/trigger_review_concurrent_requests_resp3_body_${CASE_SUFFIX}.txt"
RESP3_STATUS_FILE="/tmp/trigger_review_concurrent_requests_resp3_status_${CASE_SUFFIX}.txt"
RESP4_HEADERS_FILE="/tmp/trigger_review_concurrent_requests_resp4_headers_${CASE_SUFFIX}.txt"
RESP4_BODY_FILE="/tmp/trigger_review_concurrent_requests_resp4_body_${CASE_SUFFIX}.txt"
RESP4_STATUS_FILE="/tmp/trigger_review_concurrent_requests_resp4_status_${CASE_SUFFIX}.txt"
RESP5_HEADERS_FILE="/tmp/trigger_review_concurrent_requests_resp5_headers_${CASE_SUFFIX}.txt"
RESP5_BODY_FILE="/tmp/trigger_review_concurrent_requests_resp5_body_${CASE_SUFFIX}.txt"
RESP5_STATUS_FILE="/tmp/trigger_review_concurrent_requests_resp5_status_${CASE_SUFFIX}.txt"

cleanup_files() {
  rm -f "$REQUEST_BODY_FILE" \
    "$RESP1_HEADERS_FILE" "$RESP1_BODY_FILE" "$RESP1_STATUS_FILE" \
    "$RESP2_HEADERS_FILE" "$RESP2_BODY_FILE" "$RESP2_STATUS_FILE" \
    "$RESP3_HEADERS_FILE" "$RESP3_BODY_FILE" "$RESP3_STATUS_FILE" \
    "$RESP4_HEADERS_FILE" "$RESP4_BODY_FILE" "$RESP4_STATUS_FILE" \
    "$RESP5_HEADERS_FILE" "$RESP5_BODY_FILE" "$RESP5_STATUS_FILE"
}
trap cleanup_files EXIT

printf '{}\n' > "$REQUEST_BODY_FILE"

run_request() {
  idx="$1"
  headers_file="$2"
  body_file="$3"
  status_file="$4"
  code="$(curl -sS -D "$headers_file" -o "$body_file" -w '%{http_code}' \
    -X POST \
    -H 'Content-Type: application/json' \
    --data @"$REQUEST_BODY_FILE" \
    "$BASE_URL/api/review")"
  printf '%s' "$code" > "$status_file"
}

# Given
echo "STEP: Given — prepare one isolated request body for five concurrent calls"
echo "PREREQ: No persistent setup is required; concurrency is exercised with parallel HTTP requests"

# When
echo "STEP: When — send five concurrent POST requests to /api/review"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"
run_request 1 "$RESP1_HEADERS_FILE" "$RESP1_BODY_FILE" "$RESP1_STATUS_FILE" &
PID1=$!
run_request 2 "$RESP2_HEADERS_FILE" "$RESP2_BODY_FILE" "$RESP2_STATUS_FILE" &
PID2=$!
run_request 3 "$RESP3_HEADERS_FILE" "$RESP3_BODY_FILE" "$RESP3_STATUS_FILE" &
PID3=$!
run_request 4 "$RESP4_HEADERS_FILE" "$RESP4_BODY_FILE" "$RESP4_STATUS_FILE" &
PID4=$!
run_request 5 "$RESP5_HEADERS_FILE" "$RESP5_BODY_FILE" "$RESP5_STATUS_FILE" &
PID5=$!
wait "$PID1"
wait "$PID2"
wait "$PID3"
wait "$PID4"
wait "$PID5"

echo "RESPONSE_HEADERS[1]:"
cat "$RESP1_HEADERS_FILE"
echo "RESPONSE_BODY[1]:"
cat "$RESP1_BODY_FILE"
echo "RESPONSE_STATUS[1]: $(cat "$RESP1_STATUS_FILE")"
echo "RESPONSE_HEADERS[2]:"
cat "$RESP2_HEADERS_FILE"
echo "RESPONSE_BODY[2]:"
cat "$RESP2_BODY_FILE"
echo "RESPONSE_STATUS[2]: $(cat "$RESP2_STATUS_FILE")"
echo "RESPONSE_HEADERS[3]:"
cat "$RESP3_HEADERS_FILE"
echo "RESPONSE_BODY[3]:"
cat "$RESP3_BODY_FILE"
echo "RESPONSE_STATUS[3]: $(cat "$RESP3_STATUS_FILE")"
echo "RESPONSE_HEADERS[4]:"
cat "$RESP4_HEADERS_FILE"
echo "RESPONSE_BODY[4]:"
cat "$RESP4_BODY_FILE"
echo "RESPONSE_STATUS[4]: $(cat "$RESP4_STATUS_FILE")"
echo "RESPONSE_HEADERS[5]:"
cat "$RESP5_HEADERS_FILE"
echo "RESPONSE_BODY[5]:"
cat "$RESP5_BODY_FILE"
echo "RESPONSE_STATUS[5]: $(cat "$RESP5_STATUS_FILE")"

# Then
echo "STEP: Then — assert all concurrent responses succeeded with the expected payload"
STATUS1="$(cat "$RESP1_STATUS_FILE")"
STATUS2="$(cat "$RESP2_STATUS_FILE")"
STATUS3="$(cat "$RESP3_STATUS_FILE")"
STATUS4="$(cat "$RESP4_STATUS_FILE")"
STATUS5="$(cat "$RESP5_STATUS_FILE")"
[ "$STATUS1" = "200" ] || { echo "ASSERTION_FAILED: expected response 1 HTTP 200 got ${STATUS1}"; exit 1; }
[ "$STATUS2" = "200" ] || { echo "ASSERTION_FAILED: expected response 2 HTTP 200 got ${STATUS2}"; exit 1; }
[ "$STATUS3" = "200" ] || { echo "ASSERTION_FAILED: expected response 3 HTTP 200 got ${STATUS3}"; exit 1; }
[ "$STATUS4" = "200" ] || { echo "ASSERTION_FAILED: expected response 4 HTTP 200 got ${STATUS4}"; exit 1; }
[ "$STATUS5" = "200" ] || { echo "ASSERTION_FAILED: expected response 5 HTTP 200 got ${STATUS5}"; exit 1; }
grep -F '"status":"review_triggered"' "$RESP1_BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response 1 body to contain status review_triggered"; exit 1; }
grep -F '"status":"review_triggered"' "$RESP2_BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response 2 body to contain status review_triggered"; exit 1; }
grep -F '"status":"review_triggered"' "$RESP3_BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response 3 body to contain status review_triggered"; exit 1; }
grep -F '"status":"review_triggered"' "$RESP4_BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response 4 body to contain status review_triggered"; exit 1; }
grep -F '"status":"review_triggered"' "$RESP5_BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected response 5 body to contain status review_triggered"; exit 1; }

# Cleanup
echo "STEP: Cleanup — no persistent side effects to remove"

echo "CODEVALID_TEST_ASSERTION_OK:trigger_review_concurrent_requests"
