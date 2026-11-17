#!/bin/sh
#
# Symlink one machine's dotfiles into $HOME with GNU Stow. See --help.
#
set -eu

DOTFILES=$(cd "$(dirname "$0")" && pwd -P)
cd "$DOTFILES"

die() {
    echo "install.sh: $*" >&2
    exit 1
}

help() {
    cat <<EOF
usage: $0 [--backup | --adopt] <profile>

Symlinks the packages listed in profiles/<profile> into \$HOME.

  (no option)  link everything; if any file already exists, list the
               conflicts and change nothing
  --backup     move existing files to ~/.dotfiles-backup/<time>/, then link
  --adopt      move existing files into the repo, then link. 'git diff' shows
               how this machine differed; keep hunks with 'git add -p', drop
               them with 'git restore -p'. Needs a clean working tree
  -h, --help   show this

profiles:
$(ls profiles | sed 's/^/  /')
EOF
}

# Mistakes go to stderr with exit 2; --help asked for it, so stdout and 0
usage_error() {
    [ $# -eq 0 ] || echo "install.sh: $*" >&2
    help >&2
    exit 2
}

mode=check
case "${1:-}" in
    --backup)  mode=backup; shift ;;
    --adopt)   mode=adopt;  shift ;;
    -h|--help) help; exit 0 ;;
    -*)        usage_error "unknown option: $1" ;;
esac
[ $# -eq 1 ] || usage_error
[ -f "profiles/$1" ] || usage_error "no such profile: $1"

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
# (e.g. after a submodule update) -- but only inside folders the package
# still has; Stow never visits a folder that's gone, so its links are left.
#
# Finder drops .DS_Store into any folder it opens; Stow's defaults don't skip
# it, so it would get linked into ~. Adds to Stow's default ignore list rather
# than replacing it.
run_stow() {
    stow --dir="$DOTFILES" --target="$HOME" --no-folding --ignore='\.DS_Store' --restow "$@"
}

case $mode in
backup)
    backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
    for pkg in $packages; do
        (cd "$pkg" && find . \( -name .git -o -name .gitignore -o -name .gitmodules -o -name .DS_Store \) -prune \
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
    run_stow $packages || die "stow failed (see above); if it lists conflicts, rerun with --backup (repo wins) or --adopt (merge via git)"
    ;;
esac

echo "stowed:" $packages
