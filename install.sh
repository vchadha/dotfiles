#!/bin/sh
#
# Symlink one machine's dotfiles into $HOME with GNU Stow.
#
#   ./install.sh <profile>            stow; if anything conflicts, list it and change nothing
#   ./install.sh --backup <profile>   move conflicting files to ~/.dotfiles-backup/<time>/, then stow
#   ./install.sh --adopt <profile>    pull conflicting files into the repo, then stow -- `git diff`
#                                     shows how this machine differed; keep hunks with
#                                     `git add -p`, throw them away with `git restore -p`
#
set -eu

DOTFILES=$(cd "$(dirname "$0")" && pwd -P)
cd "$DOTFILES"

die() {
    echo "install.sh: $*" >&2
    exit 1
}

usage() {
    echo "usage: $0 [--backup | --adopt] <profile>" >&2
    echo "profiles:" >&2
    ls profiles | sed 's/^/  /' >&2
    exit 2
}

mode=check
case "${1:-}" in
    --backup) mode=backup; shift ;;
    --adopt)  mode=adopt;  shift ;;
    -*)       usage ;;
esac
[ $# -eq 1 ] || usage
if [ ! -f "profiles/$1" ]; then
    echo "install.sh: no such profile: $1" >&2
    usage
fi

# Whitespace-separated package names; left unquoted below on purpose so the
# shell splits them.
packages=$(cat "profiles/$1")
for pkg in $packages; do
    [ -d "$pkg" ] || die "profile $1 lists '$pkg', but there's no $pkg/ package"
done

command -v stow > /dev/null || die "GNU Stow isn't installed (macOS: brew install stow, Arch: pacman -S stow)"

git submodule update --init

# Flags passed explicitly rather than trusting .stowrc: the target has to be
# $HOME wherever the repo lives, and without --no-folding a missing
# directory like ~/.config would become one big symlink into this repo.
# --restow makes re-runs prune links to files that have since been deleted
# (e.g. after a submodule update).
run_stow() {
    stow --dir="$DOTFILES" --target="$HOME" --no-folding --restow "$@"
}

case $mode in
backup)
    backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
    for pkg in $packages; do
        (cd "$pkg" && find . \( -name .git -o -name .gitignore -o -name .gitmodules \) -prune \
            -o \( -type f -o -type l \) -print) |
        while IFS= read -r f; do
            f=${f#./}
            target="$HOME/$f"
            # Re-running install: the target is already our symlink, keep it
            if [ -L "$target" ] && [ "$(realpath "$target")" = "$(realpath "$pkg/$f")" ]; then
                continue
            fi
            if [ -e "$target" ] || [ -L "$target" ]; then
                mkdir -p "$backup/$(dirname "$f")"
                mv "$target" "$backup/$f"
                echo "backed up ~/$f -> $backup/$f"
            fi
        done
    done
    run_stow $packages
    ;;
adopt)
    # --adopt overwrites repo files in place, so git has to be able to undo it
    if ! git diff --quiet || ! git diff --cached --quiet; then
        die "--adopt needs a clean working tree; commit or stash first"
    fi
    run_stow --adopt $packages
    if git diff --quiet; then
        echo "adopted: this machine's files already matched the repo"
    else
        git diff --stat
        echo "adopted: review with 'git diff', keep with 'git add -p', discard with 'git restore -p'"
    fi
    ;;
check)
    run_stow $packages || die "conflicts above; rerun with --backup (repo wins) or --adopt (merge via git)"
    ;;
esac

echo "stowed:" $packages
