#!/bin/sh
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause

SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit 1
    pwd
)"

TEST_NAME="check_usr_dir"
LAVA_CASE_ID="check_usr_dir"
RES_FILE="$SCRIPT_DIR/${TEST_NAME}.res"

write_early_fail() {
    echo "$LAVA_CASE_ID FAIL" > "$RES_FILE"
    echo "[FAIL] $1" >&2
    exit 0
}

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
    write_early_fail "Could not find init_env, starting at $SCRIPT_DIR"
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

if ! command -v ls >/dev/null 2>&1; then
    fail_test "ls command not found on the DUT"
fi

log_info "Starting $TEST_NAME"
log_info "Checking / and /usr directory listings"

log_info "Output of ls -l /:"
ROOT_LISTING=$(ls -l / 2>&1) || fail_test "Failed to run ls -l /"
log_info "$ROOT_LISTING"

log_info "Output of ls -l /usr:"
USR_LISTING=$(ls -l /usr 2>&1) || fail_test "Failed to run ls -l /usr"
log_info "$USR_LISTING"

for name in bin sbin lib; do
    if [ ! -L "/$name" ]; then
        fail_test "/$name is not a symbolic link"
    fi

    if [ ! -d "/usr/$name" ]; then
        fail_test "/usr/$name is missing or is not a directory"
    fi

    log_info "Verified /$name is a symbolic link and /usr/$name exists"
done

log_pass "$LAVA_CASE_ID: /bin, /sbin, and /lib are symlinks, with matching directories under /usr"
echo "$LAVA_CASE_ID PASS" > "$RES_FILE"

log_info "Completed $TEST_NAME"
exit 0