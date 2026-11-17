#!/bin/sh
#
# How install.sh handles what people type: flags in any order, --help next
# to mistakes, bad profile names. Each case runs the real script against a
# throwaway $HOME, so nothing touches yours.
#
. "$(dirname "$0")/lib.sh"

scratch_profile="$REPO/profiles/zz-test-empty-$$"
cleanup() { rm -f "$scratch_profile"; }

# Runs install.sh with the given arguments in a fresh $home; sets $code and
# fills $tmp/out and $tmp/err.
run() {
    home=$(mktemp -d "$tmp/home.XXXXXX")
    HOME=$home "$REPO/install.sh" "$@" > "$tmp/out" 2> "$tmp/err"
    code=$?
}

nothing_installed() { [ -z "$(ls -A "$home")" ]; }

run thinkpad --help
expect help_after_profile_shows_help \
    '[ $code -eq 0 ] && out_has "usage:" && [ ! -s "$tmp/err" ]'
expect help_after_profile_installs_nothing 'nothing_installed'

run --bogus thinkpad extra --backup --adopt --help
expect help_wins_over_any_mistake_on_the_line \
    '[ $code -eq 0 ] && out_has "usage:" && nothing_installed'

run -h
expect short_help_flag '[ $code -eq 0 ] && out_has "usage:"'

run macbookpro-work --backup
expect flag_after_profile_installs \
    '[ $code -eq 0 ] && [ -L "$home/.zshrc" ]'

run --backup macbookpro-work --backup
expect repeating_a_flag_is_harmless '[ $code -eq 0 ] && [ -L "$home/.zshrc" ]'

run --backup --adopt thinkpad
expect backup_and_adopt_together_rejected \
    '[ $code -eq 2 ] && err_has "can.t be used together" && nothing_installed'

run thinkpad macbookpro-work
expect two_profiles_rejected \
    '[ $code -eq 2 ] && err_has "one profile at a time" && nothing_installed'

run thinkpad -x
expect unknown_option_named_in_error \
    '[ $code -eq 2 ] && err_has "unknown option: -x" && nothing_installed'

run
expect no_profile_explains_and_shows_usage \
    '[ $code -eq 2 ] && err_has "no profile given" && err_has "usage:" && [ ! -s "$tmp/out" ]'

run nosuch
expect unknown_profile_lists_real_ones \
    '[ $code -eq 2 ] && err_has "no such profile: nosuch" && err_has "thinkpad"'

run ../../etc/passwd
expect path_outside_profiles_rejected \
    '[ $code -eq 2 ] && err_has "not a path" && nothing_installed'

run profiles/thinkpad
expect profile_given_as_path_rejected '[ $code -eq 2 ] && err_has "not a path"'

printf '   \n\n' > "$scratch_profile"
run "$(basename "$scratch_profile")"
expect empty_profile_fails_loud \
    '[ $code -eq 1 ] && err_has "doesn.t list any packages" && nothing_installed'

summary
