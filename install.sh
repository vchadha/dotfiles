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

Symlinks the packages listed in profiles/<profile> into \$HOME. Options can
go before or after the profile.

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

# Mistakes go to stderr with exit 2, saying what was wrong first; --help asked
# for it, so stdout and 0
usage_error() {
    printf 'install.sh: %s\n\n' "$*" >&2
    help >&2
    exit 2
}

# --help anywhere wins, even next to a typo, and never installs anything.
# Its own pass so nothing below can act first.
for arg in "$@"; do
    case $arg in
        -h|--help) help; exit 0 ;;
    esac
done

mode=check
profile=
for arg in "$@"; do
    case $arg in
        --backup|--adopt)
            if [ "$mode" != check ] && [ "$mode" != "${arg#--}" ]; then
                usage_error "--backup and --adopt can't be used together"
            fi
            mode=${arg#--}
            ;;
        -*)
            usage_error "unknown option: $arg"
            ;;
        *)
            [ -z "$profile" ] || usage_error "one profile at a time (got '$profile' and '$arg')"
            profile=$arg
            ;;
    esac
done
[ -n "$profile" ] || usage_error "no profile given"
case $profile in
    # Also keeps a name like ../../x from reading a file outside profiles/
    */*) usage_error "give the profile's name, not a path (e.g. thinkpad, not $profile)" ;;
esac
[ -f "profiles/$profile" ] || usage_error "no such profile: $profile"

# Whitespace-separated package names; left unquoted below on purpose so the
# shell splits them.
packages=$(cat "profiles/$profile")
[ -n "$(echo $packages)" ] || die "profiles/$profile doesn't list any packages"
for pkg in $packages; do
    [ -d "$pkg" ] || die "profile $profile lists '$pkg', but there's no $pkg/ package"
done

command -v stow > /dev/null || die "GNU Stow isn't installed (macOS: brew install stow, Arch: pacman -S stow)"

# Checks out the plugins at the commits this repo pins. That also undoes a
# plugin you've moved but not committed -- the price of `dots pull && dots
# install` picking up pinned updates from other machines.
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
    move_to_backup() { # <path under ~>
        mkdir -p "$backup/$(dirname "$1")"
        mv "$HOME/$1" "$backup/$1"
        echo "backed up ~/$1 -> $backup/$1"
    }
    for pkg in $packages; do
        (cd "$pkg" && find . \( -name .git -o -name .gitignore -o -name .gitmodules -o -name .DS_Store \) -prune \
            -o \( -type f -o -type l \) -print) |
        while IFS= read -r f; do
            f=${f#./}
            # A file or a link where the package has a folder blocks
            # everything under it, so back up that one item instead. Such a
            # link is often an old Stow link into this repo, and looking
            # inside it would "back up" the repo's own files.
            blocker=
            dir=$(dirname "$f")
            while [ "$dir" != . ]; do
                if [ -L "$HOME/$dir" ] || { [ -e "$HOME/$dir" ] && [ ! -d "$HOME/$dir" ]; }; then
                    blocker=$dir
                fi
                dir=$(dirname "$dir")
            done
            if [ -n "$blocker" ]; then
                move_to_backup "$blocker"
                continue
            fi
            # Re-running install: the target is already our symlink, keep it
            target="$HOME/$f"
            if [ -L "$target" ] && [ "$(realpath "$target")" = "$(realpath "$pkg/$f")" ]; then
                continue
            fi
            if [ -e "$target" ] || [ -L "$target" ]; then
                move_to_backup "$f"
            fi
        done
    done
    run_stow $packages || die "stow failed after the backup (see above); your old files are in $backup"
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
