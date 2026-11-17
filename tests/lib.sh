# Shared by the tests/test-*.sh suites; sourced, not run. Gives each suite
# $REPO, a throwaway $tmp, and expect/summary for counting results.
#
# A suite that needs extra teardown defines cleanup() after sourcing this.

set -u

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
tmp=$(mktemp -d)
cleanup() { :; }
trap 'cleanup; rm -rf "$tmp"' EXIT

passes=0
fails=0
code=

# expect <test name> <shell condition>
#
# On failure, prints the condition plus the start of $tmp/out and $tmp/err,
# which is where suites send the output of whatever they just ran.
expect() {
    if eval "$2"; then
        passes=$((passes + 1))
    else
        fails=$((fails + 1))
        echo "FAIL: $1"
        echo "  condition: $2  (exit was ${code:-n/a})"
        [ -f "$tmp/out" ] && sed 's/^/  stdout: /' "$tmp/out" | head -5
        [ -f "$tmp/err" ] && sed 's/^/  stderr: /' "$tmp/err" | head -5
    fi
}

out_has() { grep -q -- "$1" "$tmp/out"; }
err_has() { grep -q -- "$1" "$tmp/err"; }

summary() {
    echo "$(basename "$0"): $passes passed, $fails failed"
    [ "$fails" -eq 0 ]
}
