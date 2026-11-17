# Read by sh login shells, and by some display managers' session scripts, so
# it has to stay POSIX: `.` rather than `source`, which dash doesn't have.
# There's no interactive file: sh only reads one through $ENV, and
# .shell/interactive is bash/zsh-only (as are nvm and SDKMAN, which the
# macos package loads there).
. "$HOME/.shell/env"
