#!/bin/sh
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause

SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit 1
    pwd
)"
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

TESTNAME="Systemd_Udev_Service"
test_path="$(find_test_case_by_name "$TESTNAME")" || {
    log_fail "$TESTNAME, test directory not found"
    echo "$TESTNAME FAIL" > "./$TESTNAME.res"
    exit 1
}

cd "$test_path" || exit 1
RES_FILE="./${TESTNAME}.res"
rm -f "$RES_FILE"

fail_test() {
    log_fail "$1"
    echo "$TESTNAME FAIL" > "$RES_FILE"
    exit 0
}

ADB_BIN="${ADB:-adb}"

if ! command -v "$ADB_BIN" >/dev/null 2>&1; then
    fail_test "adb command not found: $ADB_BIN"
fi

log_info "-----------------------------------------------------------------------------------------"
log_info "------------------- Starting ${TESTNAME} Testcase ----------------------------"
log_info "==== Test Initialization ===="
log_info "Checking for systemd-udevd on the DUT"

if [ -n "${ADB_SERIAL:-}" ]; then
    PS_OUTPUT=$("$ADB_BIN" -s "$ADB_SERIAL" shell "ps -ef" 2>&1)
    ADB_STATUS=$?
else
    PS_OUTPUT=$("$ADB_BIN" shell "ps -ef" 2>&1)
    ADB_STATUS=$?
fi

if [ "$ADB_STATUS" -ne 0 ]; then
    log_info "ADB command output: $PS_OUTPUT"
    fail_test "Failed to run ps -ef through adb"
fi

# Remove carriage returns that may be returned by the remote shell.
PS_OUTPUT=$(printf '%s\n' "$PS_OUTPUT" | tr -d '\r')

MATCHED_LINE=$(
    printf '%s\n' "$PS_OUTPUT" |
        grep -E '^[[:space:]]*[0-9]+[[:space:]]+root[[:space:]]+[0-9]+:[0-9]{2}[[:space:]]+/lib/systemd/systemd-udevd([[:space:]]|$)' ||
        true
)

if [ -z "$MATCHED_LINE" ]; then
    log_info "Output from ps -ef:"
    log_info "$PS_OUTPUT"
    fail_test "Expected systemd-udevd process line was not found"
fi

log_info "Matching process line: $MATCHED_LINE"
log_pass "$TESTNAME, systemd-udevd is running with the expected process format"
echo "$TESTNAME PASS" > "$RES_FILE"
log_info "------------------- Completed ${TESTNAME} Testcase ----------------------------"
exit 0