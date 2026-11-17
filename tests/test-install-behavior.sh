#!/bin/sh
#
# What install.sh does to a home folder: conflicts, --backup, --adopt,
# re-runs, and every profile linking cleanly.
#
. "$(dirname "$0")/lib.sh"
copy_repo

# Later run_install calls reuse this home until the next new_home
new_home() { home=$(mktemp -d "$tmp/home.XXXXXX"); }

# run_install <args...>: run the copy's install.sh into $home, from another folder
run_install() {
    (cd "$tmp" && HOME=$home "$repo/install.sh" "$@") > "$tmp/out" 2> "$tmp/err"
    code=$?
}

reset_repo() { git -C "$repo" reset -q --hard && git -C "$repo" clean -qfd; }

links_in_home() { find "$home" -type l | wc -l | tr -d ' '; }
# -L follows links, so only those whose target is missing still show as links
broken_links() { find -L "$home" -type l; }
backups() { ls "$home/.dotfiles-backup" 2> /dev/null | wc -l | tr -d ' '; }
links_to_repo() { [ "$(realpath "$home/$1")" = "$(realpath "$repo/$2")" ]; }

profile=macbookpro-work

#
# A file already in the way
#

new_home
echo mine > "$home/.zshrc"
run_install "$profile"
expect conflict_without_flag_fails_and_suggests_flags \
    '[ $code -eq 1 ] && err_has "--backup" && err_has "--adopt"'
expect conflict_without_flag_changes_nothing \
    '[ ! -L "$home/.zshrc" ] && [ "$(cat "$home/.zshrc")" = mine ] && [ "$(links_in_home)" -eq 0 ]'

#
# --backup
#

new_home
echo mine > "$home/.zshrc"
ln -s /nonexistent/vimrc "$home/.vimrc"
mkdir -p "$home/Library/Application Support/gotop"
echo mine > "$home/Library/Application Support/gotop/gotop.conf"
run_install --backup "$profile"
b=$(ls -d "$home"/.dotfiles-backup/* 2> /dev/null | head -1)
expect backup_links_everything '[ $code -eq 0 ] && links_to_repo .zshrc common/.zshrc'
expect backup_keeps_the_old_file '[ "$(cat "$b/.zshrc")" = mine ]'
expect backup_moves_a_symlink_pointing_elsewhere \
    '[ -L "$b/.vimrc" ] && links_to_repo .vimrc common/.vimrc'
expect backup_handles_spaces_in_paths \
    '[ "$(cat "$b/Library/Application Support/gotop/gotop.conf")" = mine ] &&
     links_to_repo "Library/Application Support/gotop/gotop.conf" "macos/Library/Application Support/gotop/gotop.conf"'

run_install --backup "$profile"
expect backup_rerun_backs_up_nothing_new '[ $code -eq 0 ] && [ "$(backups)" -eq 1 ]'

new_home
echo mine > "$home/.zshrc"
mkdir -p "$home/.config"
echo mine > "$home/.config/gotop"
run_install --backup "$profile"
b=$(ls -d "$home"/.dotfiles-backup/* 2> /dev/null | head -1)
expect backup_moves_a_file_where_the_repo_has_a_folder \
    '[ $code -eq 0 ] && [ "$(cat "$b/.config/gotop")" = mine ] && links_to_repo .zshrc common/.zshrc'

# An old Stow link that points a whole folder into the repo
new_home
ln -s "$repo/common/.zsh" "$home/.zsh"
run_install --backup "$profile"
expect backup_never_moves_repo_files_through_an_old_folder_link \
    '[ $code -eq 0 ] && [ -z "$(git -C "$repo" status --short)" ] && links_to_repo .zsh/env common/.zsh/env'
reset_repo

new_home
echo finder > "$home/.DS_Store"
run_install --backup "$profile"
expect backup_leaves_finder_files_alone \
    '[ $code -eq 0 ] && [ "$(cat "$home/.DS_Store")" = finder ] && [ "$(backups)" -eq 0 ]'

#
# --adopt
#

new_home
echo "# local edit" >> "$repo/common/.vimrc"
echo mine > "$home/.zshrc"
run_install --adopt "$profile"
expect adopt_refuses_a_dirty_tree \
    '[ $code -eq 1 ] && err_has "clean working tree" && [ "$(links_in_home)" -eq 0 ]'
reset_repo

run_install --adopt "$profile"
expect adopt_moves_the_machine_file_into_the_repo \
    '[ $code -eq 0 ] && links_to_repo .zshrc common/.zshrc && [ "$(cat "$repo/common/.zshrc")" = mine ]'
expect adopt_points_at_git_diff 'out_has "git diff"'
reset_repo

#
# Re-running
#

new_home
echo "# test" > "$repo/common/.zz-test"
run_install "$profile"
expect new_file_gets_linked '[ $code -eq 0 ] && [ -L "$home/.zz-test" ]'
rm "$repo/common/.zz-test"
run_install "$profile"
expect rerun_removes_link_to_deleted_file '[ $code -eq 0 ] && [ ! -L "$home/.zz-test" ]'

echo finder > "$repo/common/.DS_Store"
echo finder > "$repo/common/.config/gotop/.DS_Store"
run_install "$profile"
expect finder_files_in_repo_never_linked \
    '[ $code -eq 0 ] && [ -z "$(find "$home" -name .DS_Store)" ]'
reset_repo

#
# Every profile
#

for profile_file in "$repo"/profiles/*; do
    p=$(basename "$profile_file")
    new_home
    run_install "$p"
    expect "profile_${p}_installs" '[ $code -eq 0 ] && [ "$(links_in_home)" -gt 0 ]'
    expect "profile_${p}_has_no_broken_links" '[ -z "$(broken_links)" ]'
    run_install "$p"
    expect "profile_${p}_rerun_is_clean" '[ $code -eq 0 ] && [ ! -s "$tmp/err" ]'
done

summary
