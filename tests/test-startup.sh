#!/bin/sh
#
# Every config that runs at startup loads cleanly in a freshly installed home:
# zsh, bash and sh in each way they get started, plus vim and tmux. Covers
# the profiles for the OS this runs on; each gets a throwaway $HOME and a
# clean environment, like a new terminal or an ssh session would.
#
. "$(dirname "$0")/lib.sh"

case $(uname -s) in
    Darwin) os_package=macos ;;
    Linux)  os_package=arch ;;
    *)      echo "$(basename "$0"): no package for $(uname -s), skipping"; exit 0 ;;
esac

# Resolved now because the shells below start with a bare PATH
zsh=$(command -v zsh) || { echo "zsh isn't installed" >&2; exit 1; }
bash=$(command -v bash)
dash=$(command -v dash || true)
vim=$(command -v vim || true)
tmux=$(command -v tmux || true)
# Own socket file inside $tmp: a -L name would leave a socket behind in the
# system tmux folder after every run
tmux_socket="$tmp/tmux.sock"

cleanup() {
    [ -z "$tmux" ] || "$tmux" -S "$tmux_socket" kill-server 2> /dev/null
    # The arch package starts an ssh-agent in interactive shells
    for agent_env in "$tmp"/home.*/.ssh/environment; do
        [ -r "$agent_env" ] || continue
        (. "$agent_env" > /dev/null; kill "$SSH_AGENT_PID" 2> /dev/null)
    done
}

# What each shell reports back. Plain echo so sh, bash and zsh all run it;
# the "probe " prefix tells these lines apart from anything startup printed.
PROBE='echo "probe PATH=$PATH"; echo "probe EDITOR=${EDITOR:-}"; echo "probe LANG=${LANG:-}"; echo "probe LOCAL=${DOTFILES_TEST_LOCAL:-}"'

# Runs a command with only the variables a login (terminal, sshd) would set.
# PROBE is exported too, for the nested-shell case.
clean_env() {
    env -i HOME="$home" USER="$user" LOGNAME="$user" TERM=xterm-256color \
        PATH=/usr/bin:/bin:/usr/sbin:/sbin PROBE="$PROBE" "$@" \
        < /dev/null > "$tmp/out" 2> "$tmp/err"
    code=$?
}
user=${USER:-$(id -un)}

path_entries() { sed -n 's/^probe PATH=//p' "$tmp/out" | tr : '\n'; }
line_of() { path_entries | grep -nx -- "$1" | head -1 | cut -d: -f1; }

no_duplicate_path_entries() { [ -z "$(path_entries | sort | uniq -d)" ]; }
homebrew_before_system() {
    b=$(line_of /opt/homebrew/bin) u=$(line_of /usr/bin)
    [ -n "$b" ] && [ -n "$u" ] && [ "$b" -lt "$u" ]
}
local_bin_after_system() {
    l=$(line_of "$home/.local/bin") u=$(line_of /usr/bin)
    [ -n "$l" ] && [ -n "$u" ] && [ "$l" -gt "$u" ]
}
# Anything startup printed would land in scp/rsync streams over ssh
printed_nothing_else() { ! grep -qv '^probe ' "$tmp/out"; }

# check_shell <label> <shell> <args...>: start the shell, then run the
# checks every startup mode has to pass
check_shell() {
    label="$profile, $1"
    shift
    clean_env "$@"
    expect "$label: starts without errors" '[ $code -eq 0 ] && [ ! -s "$tmp/err" ]'
    expect "$label: prints nothing of its own" printed_nothing_else
    expect "$label: env loaded (EDITOR, LANG)" \
        'out_has "^probe EDITOR=vim$" && out_has "^probe LANG=en_US.UTF-8$"'
    expect "$label: local/env overlay loaded" 'out_has "^probe LOCAL=loaded$"'
    expect "$label: no duplicate PATH entries" no_duplicate_path_entries
    expect "$label: sees ~/.local/bin (uv tools, scripts over ssh)" '[ -n "$(line_of "$home/.local/bin")" ]'
    expect "$label: ~/.local/bin after /usr/bin, so it can't shadow system commands" \
        local_bin_after_system
    if [ "$brew_expected" = yes ]; then
        expect "$label: Homebrew before /usr/bin on PATH" homebrew_before_system
    fi
}

for profile_file in "$REPO"/profiles/*; do
    profile=$(basename "$profile_file")
    case " $(tr -s '[:space:]' ' ' < "$profile_file") " in
        *" $os_package "*) ;;
        *) continue ;;
    esac

    home=$(mktemp -d "$tmp/home.XXXXXX")
    HOME=$home "$REPO/install.sh" "$profile" > "$tmp/out" 2> "$tmp/err"
    code=$?
    expect "$profile: installs" '[ $code -eq 0 ]'
    [ $code -eq 0 ] || continue

    mkdir -p "$home/.shell/local"
    echo 'export DOTFILES_TEST_LOCAL=loaded' > "$home/.shell/local/env"

    brew_expected=no
    [ "$os_package" = macos ] && [ -x /opt/homebrew/bin/brew ] && brew_expected=yes

    check_shell "zsh -c (ssh host cmd, scp)"  "$zsh" -c "$PROBE"
    check_shell "zsh login"                   "$zsh" -l -c "$PROBE"
    check_shell "zsh interactive"             "$zsh" -i -c "$PROBE"
    check_shell "zsh login interactive"       "$zsh" -l -i -c "$PROBE"
    check_shell "zsh inside a login zsh"      "$zsh" -l -i -c "'$zsh' -i -c \"\$PROBE\""
    # Where duplicates come from: macOS's /etc/zprofile reorders the PATH the
    # outer shell set up, so brew shellenv no longer finds Homebrew first and
    # adds it again
    check_shell "login zsh inside a login zsh (tmux pane)" \
                                              "$zsh" -l -i -c "'$zsh' -l -i -c \"\$PROBE\""
    check_shell "bash login"                  "$bash" -l -c "$PROBE"
    check_shell "sh login"                    /bin/sh -l -c "$PROBE"
    if [ -n "$dash" ]; then
        check_shell "dash login (POSIX)"      "$dash" -l -c "$PROBE"
    fi

    clean_env "$zsh" -i -c 'dots rev-parse --show-toplevel'
    expect "$profile: dots finds the repo" '[ "$(cat "$tmp/out")" = "$REPO" ]'

    clean_env "$zsh" -i -c 'echo "${_comps[dots]-} ${_comps[install.sh]-}"'
    expect "$profile: tab completion registered for dots and install.sh" \
        '[ "$(cat "$tmp/out")" = "_dots _dots" ]'

    if [ -n "$vim" ]; then
        # -Es skips the vimrc unless -u names it, and exits 1 on any error in it
        clean_env "$vim" -N -u "$home/.vimrc" -i NONE -Es +qa!
        expect "$profile: .vimrc loads without errors" '[ $code -eq 0 ]'
    fi

    if [ -n "$tmux" ]; then
        # Read as a separate client command against a private server: errors
        # in a file given with -f, or in `source-file -n`, are swallowed
        "$tmux" -S "$tmux_socket" kill-server 2> /dev/null
        clean_env "$tmux" -S "$tmux_socket" -f /dev/null new-session -d
        clean_env "$tmux" -S "$tmux_socket" source-file "$home/.tmux.conf"
        expect "$profile: .tmux.conf loads without errors" '[ $code -eq 0 ] && [ ! -s "$tmp/err" ] && [ ! -s "$tmp/out" ]'
    fi
done

summary
