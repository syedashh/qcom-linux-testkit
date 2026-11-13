#!/bin/sh
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause

SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit 1
    pwd
)"

TESTNAME="Systemd_Udev_Service"
LAVA_CASE_ID="udev_service_info"
RES_FILE="$SCRIPT_DIR/${TESTNAME}.res"

INIT_ENV=""
SEARCH="$SCRIPT_DIR"

while [ "$SEARCH" != "/" ]; do
    if [ -f "$SEARCH/init_env" ]; then
        INIT_ENV="$SEARCH/init_env"
        break
    fi
    SEARCH=$(dirname "$SEARCH")
done

if [ -z "$INIT_ENV" ]; then
    echo "[ERROR] Could not find init_env, starting at $SCRIPT_DIR" >&2
    exit 1
fi

if [ -z "${__INIT_ENV_LOADED:-}" ]; then
    # shellcheck disable=SC1090
    . "$INIT_ENV"
    __INIT_ENV_LOADED=1
fi

# shellcheck disable=SC1091
. "$TOOLS/functestlib.sh"

rm -f "$RES_FILE"

fail_test() {
    log_fail "$1"
    echo "$LAVA_CASE_ID FAIL" > "$RES_FILE"
    exit 0
}

test_path="$(find_test_case_by_name "$TESTNAME")"
if [ -z "$test_path" ] || [ ! -d "$test_path" ]; then
    fail_test "$TESTNAME test directory not found"
fi

cd "$test_path" || fail_test "Could not enter test directory: $test_path"
RES_FILE="$test_path/${TESTNAME}.res"

if ! command -v ps >/dev/null 2>&1; then
    fail_test "ps command not found on the DUT"
fi

log_info "-----------------------------------------------------------------------------------------"
log_info "------------------- Starting ${TESTNAME} Testcase ----------------------------"
log_info "==== Test Initialization ===="
log_info "Checking for systemd-udevd on the DUT"

PS_OUTPUT=$(ps -ef 2>&1)
PS_STATUS=$?

if [ "$PS_STATUS" -ne 0 ]; then
    log_info "ps command output: $PS_OUTPUT"
    fail_test "Failed to run ps -ef on the DUT"
fi

MATCHED_LINE=$(
    printf '%s\n' "$PS_OUTPUT" |
        grep -E '^[[:space:]]*root[[:space:]].*/lib/systemd/systemd-udevd([[:space:]]|$)' ||
        true
)

if [ -z "$MATCHED_LINE" ]; then
    log_info "Output from ps -ef:"
    log_info "$PS_OUTPUT"
    fail_test "Expected root-owned /lib/systemd/systemd-udevd process was not found"
fi

log_info "Matching process line: $MATCHED_LINE"
log_pass "$LAVA_CASE_ID, systemd-udevd is running with the expected process format"

echo "$LAVA_CASE_ID PASS" > "$RES_FILE"

log_info "------------------- Completed ${TESTNAME} Testcase ----------------------------"
exit 0