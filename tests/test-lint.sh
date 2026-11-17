#!/bin/sh
#
# Static checks over the tracked files: shell syntax in every dialect that
# reads a file, configs that parse, no retired Nerd Font icons, scripts kept
# executable, and nothing that looks like a secret can be committed.
#
. "$(dirname "$0")/lib.sh"

command -v python3 > /dev/null || { echo "python3 is needed for these checks" >&2; exit 1; }
cd "$REPO"

# Tracked regular files, skipping submodules (mode 160000), as "mode path"
git ls-files -s | awk '$1 != "160000" { mode = $1; sub(/^[^\t]*\t/, ""); print mode " " $0 }' > "$tmp/files"

# Shells that source a shebang-less config file, by its path inside the
# package. .shell/env files are also read by sh (via .profile), so they have
# to stay POSIX; the rest of .shell/ is bash and zsh only.
config_dialects() {
    case $1 in
        .zsh/*.md) ;;
        .zshrc|.zshenv|.zprofile|.zsh/*)    echo zsh ;;
        .bashrc|.bash_profile|.bash/*)      echo bash ;;
        .profile)                           echo sh ;;
        .shell/env|.shell/*/env)            echo sh bash zsh ;;
        .shell/*)                           echo bash zsh ;;
    esac
}

shebang_dialect() {
    case $(head -n 1 "$1") in
        '#!/bin/sh'*|'#!/usr/bin/env sh'*)     echo sh ;;
        '#!/bin/bash'*|'#!/usr/bin/env bash'*) echo bash ;;
        '#!/bin/zsh'*|'#!/usr/bin/env zsh'*)   echo zsh ;;
        '#!/usr/bin/env python3'*)             echo python ;;
    esac
}

# dash is the strictest POSIX shell around (it's Debian's /bin/sh), so prefer
# it for sh; /bin/sh on macOS is bash in POSIX mode and accepts bashisms
sh_checker=$(command -v dash || echo /bin/sh)
[ "$sh_checker" != /bin/sh ] ||
    skip "strict POSIX syntax check -- dash isn't installed, so /bin/sh checks the sh files and may accept bashisms"

syntax_ok() { # <dialect> <file>
    case $1 in
        # dash for strictness, /bin/sh because it's what actually runs them
        sh)     "$sh_checker" -n "$2" && /bin/sh -n "$2" ;;
        bash)   bash -n "$2" ;;
        zsh)    zsh -n "$2" ;;
        python) python3 -I -c 'import ast, sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])' "$2" ;;
    esac > "$tmp/out" 2> "$tmp/err"
}

checked=0
while read -r mode path; do
    [ -f "$path" ] || continue
    dialects=$(shebang_dialect "$path")
    if [ -n "$dialects" ]; then
        expect "$path has a shebang, so it's executable" '[ "$mode" = 100755 ]'
    else
        # Sourced configs and images don't need to be executable
        expect "$path is only executable if it's a script" '[ "$mode" != 100755 ] || head -c 2 "$path" | grep -q "#!"'
        dialects=$(config_dialects "${path#*/}")
    fi
    for d in $dialects; do
        checked=$((checked + 1))
        expect "$path parses as $d" 'syntax_ok "$d" "$path"'
    done
done < "$tmp/files"
expect "found shell configs to check (got $checked)" '[ $checked -gt 20 ]'

# PATH changes in an interactive file never reach scripts or `ssh host cmd`
grep -E '(^|/)(\.zshrc|\.bashrc|\.(shell|zsh)/(.+/)?interactive)$' "$tmp/files" | cut -d" " -f2- |
    while IFS= read -r path; do grep -nHE 'append_path|prepend_path|(^|[^A-Z_])PATH=|(^|[^A-Za-z_])path\+?=\(' "$path"; done > "$tmp/out"
expect "PATH is only changed in env files" '[ ! -s "$tmp/out" ]'

# Waybar reads JSON with // comments, which Python's json doesn't take
expect "waybar config parses" 'python3 -I - arch/.config/waybar/config > "$tmp/out" 2> "$tmp/err" <<"PY"
import json, sys
src, out, i, in_str = open(sys.argv[1]).read(), [], 0, False
while i < len(src):
    c = src[i]
    if in_str:
        out.append(c)
        if c == "\\":
            out.append(src[i + 1]); i += 1
        elif c == "\"":
            in_str = False
    elif c == "\"":
        in_str = True; out.append(c)
    elif src.startswith("//", i):
        i = src.find("\n", i) - 1 if "\n" in src[i:] else len(src)
    else:
        out.append(c)
    i += 1
json.loads("".join(out))
PY'

# Nerd Fonts 3.0 moved Material Design icons from U+F500-FD46 to U+F0001+,
# and only U+F500-F533 got reused (by Octicons), per v3.4.0's glyphnames.json.
# Anything in the rest shows as a blank box with a current font.
expect "no icons from the codepoints Nerd Fonts 3 retired (U+F534-FD46)" \
    'cut -d" " -f2- "$tmp/files" | python3 -I -c "
import sys
bad = 0
for path in sys.stdin.read().splitlines():
    try:
        text = open(path, encoding=\"utf-8\").read()
    except (UnicodeDecodeError, IsADirectoryError, FileNotFoundError):
        continue  # binary files (wallpapers) and anything not checked out
    for n, line in enumerate(text.splitlines(), 1):
        for ch in line:
            if 0xF534 <= ord(ch) <= 0xFD46:
                print(f\"{path}:{n}: U+{ord(ch):04X}\")
                bad += 1
sys.exit(bad > 0)
" > "$tmp/out" 2> "$tmp/err"'

#
# Secrets
#

for secret in \
    common/.ssh/id_ed25519 common/.ssh/known_hosts \
    common/.gnupg/private-keys-v1.d/x.key common/.password-store/x.gpg \
    macos/.config/gh/hosts.yml common/.aws/credentials common/.aws/sso/cache/t.json \
    common/.config/gcloud/credentials.db common/.kube/config common/.docker/config.json \
    common/.cargo/credentials.toml common/.netrc common/.git-credentials common/.npmrc \
    common/.pypirc common/.env common/.env.local common/.envrc host-thinkpad/server.pem \
    common/.zsh_history common/.shell/local/env common/.zsh/local/env \
    common/.claude/.credentials.json common/.claude/projects/x.jsonl \
    common/.claude/settings.local.json common/.claude.json common/.claude.json.backup
do
    expect "gitignore catches $secret" 'git check-ignore -q "$secret"'
done

for kept in common/.ssh/config macos/.config/gh/config.yml common/.zshrc common/.claude/CLAUDE.md \
    tests/zz-new.sh profiles/zz-new
do
    expect "gitignore leaves $kept trackable" '! git check-ignore -q "$kept"'
done


expect "no tracked file is ignored or looks like a secret (hooks/pre-commit passes)" 'hooks/pre-commit > "$tmp/out" 2> "$tmp/err"'

copy_repo
# refused <path>: stage the file (already written) with -f and run the hook
refused() {
    git -C "$repo" add -f -- "$1" &&
        (cd "$repo" && hooks/pre-commit) > "$tmp/out" 2> "$tmp/err"
    status=$?
    git -C "$repo" rm -q --cached -- "$1"
    [ $status -ne 0 ] && err_has "$1"
}

mkdir -p "$repo/common/.config/gh"
echo 'oauth_token: x' > "$repo/common/.config/gh/hosts.yml"
expect "pre-commit refuses a secret path, even one added with -f" 'refused common/.config/gh/hosts.yml'
echo 'export TOKEN=x' > "$repo/common/.envrc"
expect "pre-commit refuses direnv's .envrc" 'refused common/.envrc'

# Samples are built at runtime so this file doesn't trip the hook itself
x36=$(printf '%036d' 0)
token_refused() { # <what> <sample>
    echo "$2" > "$repo/common/.zz-key"
    expect "pre-commit refuses $1 in any file" 'refused common/.zz-key'
}
token_refused "a private key" "$(printf -- '-----BEGIN OPENSSH PRIVATE %s-----' KEY)"
token_refused "an AWS key" "AKIA$(printf '%016d' 0)"
token_refused "a classic GitHub token" "ghp_$x36"
token_refused "a GitHub app token in the long APPID_JWT form" "ghs_12345_$x36"
token_refused "a fine-grained GitHub token" "github_pat_$x36$x36"
token_refused "an Anthropic key" "sk-ant-api03-$x36"

summary
