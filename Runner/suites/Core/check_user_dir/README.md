# check_user_dir

## Purpose

Checks the DUT's root and `/usr` directory layout without using `adb`.

The test runs locally on the DUT and verifies that:

- `/bin`, `/sbin`, and `/lib` are symbolic links.
- `/usr/bin`, `/usr/sbin`, and `/usr/lib` exist as directories.

It also logs the output of `ls -l /` and `ls -l /usr`.

## Requirements

- Run the test on the DUT.
- The DUT must provide `ls`.
- The testkit `Runner` directory, including `init_env` and shared utilities,
  must remain together.
- The suite directory must be writable so the test can create its result file.

## Run

From this directory:

```sh
./run.sh