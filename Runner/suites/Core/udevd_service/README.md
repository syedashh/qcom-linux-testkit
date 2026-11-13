# Systemd_Udev_Service

## Purpose

Checks that `systemd-udevd` is running on the DUT.

The test runs `ps -ef` locally on the DUT and looks for a root-owned
`/lib/systemd/systemd-udevd` process.

## Requirements

- Run this test on the DUT.
- The DUT must have a working `ps` command.
- The testkit `Runner` directory, including `init_env` and shared utilities,
  must be kept together.
- The test directory must be writable so the test can create its result file.

## Run

From the test directory:

```sh
./run.sh