#!/bin/sh
#
# Runs every tests/test-*.sh suite; exits non-zero if any of them failed.
#
dir=$(cd "$(dirname "$0")" && pwd -P)
status=0
for suite in "$dir"/test-*.sh; do
    "$suite" || status=1
done
exit $status
