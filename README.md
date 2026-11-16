# . dotfiles

System Configuration Files Galore

Managed with [GNU Stow](https://www.gnu.org/software/stow/): each top-level
folder is a *package* that mirrors `$HOME`, and each machine's *profile*
lists which packages it gets.

## Layout

| Package | Goes on | What's in it |
|---|---|---|
| `common/` | every machine | zsh/bash/sh layers, vim + plugins, tmux, gotop |
| `macos/` | every Mac | Homebrew, language toolchains, Colima, `og`, pbcopy for tmux |
| `arch/` | every Arch machine | sway, waybar, mako, rofi, gtk, desktop scripts, ssh-agent, wl-copy for tmux |
| `host-thinkpad/` | the ThinkPad | monitors/touchpad (`sway/host.conf`), kitty, mpd/ncmpcpp, zathura |
| `host-macbookpro-home/` | the home MacBook Pro | Playdate SDK, nom, Unity |

`profiles/<machine>` is a single line, e.g. `common macos host-macbookpro-home`.

## Install

1. Install the prerequisites:
   - **macOS**: [Homebrew](https://brew.sh), then `brew install stow`
   - **Arch**: `pacman -S git stow zsh vim tmux`
2. Clone it anywhere and run the installer with your profile:

   ```sh
   git clone https://github.com/vchadha/dotfiles ~/Developer/dotfiles
   cd ~/Developer/dotfiles
   ./install.sh <profile>        # no argument lists the profiles
   ```

3. If zsh isn't already your shell: `chsh -s "$(command -v zsh)"`
4. vim-devicons needs a [Nerd Font](https://www.nerdfonts.com) set in your terminal.

### When files already exist

Stow won't overwrite real files. If any of the files it wants to link already
exist, `install.sh` lists them and **changes nothing**. Then pick one of:

| Command | What happens | Use it when |
|---|---|---|
| `./install.sh --backup <profile>` | Moves the existing files to `~/.dotfiles-backup/<timestamp>/`, then links | New machine; the repo should win |
| `./install.sh --adopt <profile>` | Moves the existing files *into the repo* and links them, so `git diff` shows how the machine differed. Keep hunks with `git add -p`, drop them with `git restore -p` | The machine has edits worth merging |

`--adopt` needs a clean working tree, since git is the undo.

### Updating

```sh
git pull && ./install.sh <profile>
```

Re-running is safe. It picks up new files (e.g. after a plugin update) and
prunes links to deleted ones.

## Machine-specific settings

Shell config loads in layers, most general first: `common`, then
`~/.shell/os/`, then `~/.shell/host/`, then `~/.shell/local/`, with `env` and
`interactive` files at each level (zsh-only bits go under `~/.zsh/os|host|local/`).

- **`os/`** comes from `macos/` or `arch/`. It holds things true of every machine of that kind.
- **`host/`** comes from `host-<machine>/`. It holds hardware details and tools only that machine has.
- **`local/`** is **never tracked**. Put secrets, credentials, and one-off tweaks here.

  For example, `~/.shell/local/env`:

  ```sh
  export AWS_ACCESS_KEY_ID=...
  ```

The same idea applies outside the shell. tmux sources `~/.tmux.clipboard.conf`
from the OS package, and sway includes `~/.config/sway/host.conf` from the host
package. **Every sway machine needs a `host.conf`.**

## Adding a machine

- **Another Mac or Arch box:** add `profiles/<name>` (e.g. `common macos`). Add a
  `host-<name>/` package only if it needs something the others don't.
- **A new OS (e.g. Debian):** add a `<os>/` package that provides
  `.shell/os/{env,interactive}` and `.tmux.clipboard.conf`. If it's headless,
  that's the time to split sway out of `arch/` into its own package.

## Gotchas

- **Installers that append to `~/.zshrc` (nvm, bun, opam, …)** are now editing
  `common/.zshrc` in this repo through the symlink. It shows up in `git status`.
  Move the lines into `macos/`, the host package, or `local/`.
- **Two packages can't own the same file.** That's what stops `macos` and
  `arch` from being installed together.

---

### dotfiles for my ThinkPad Arch Rice

System setup:

+ **OS**: Arch Linux
+ **DSP** [wayland](https://github.com/wayland-project/wayland)
+ **WM**: [sway](https://github.com/swaywm/sway)
+ **Taskbar**: [waybar](https://github.com/Alexays/Waybar)
+ **Shell**: [zsh](https://wiki.archlinux.org/index.php/Zsh)
+ **Terminal**: [kitty](https://github.com/kovidgoyal/kitty/)
+ **Editor**: [vim](https://github.com/vim/vim)
+ **File Manager**: [nautilus](https://github.com/GNOME/nautilus)
+ **Launcher**: [rofi](https://github.com/davatorium/rofi/)
+ **Browser**: Firefox

## Preview

### Terminals
![alt text][terminals]

### Firfox with Tabliss
![alt text][firefox]

### Applications
![alt text][applications]

* [Zathura](https://github.com/pwmt/zathura)
* [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp)
* Spotify

### Nautilus File Explorer
![alt text][file_explorer]

### Rofi Launcher
![alt text][launcher]

### Rofi Power Script
![alt text][power_script]

### Process Managers
![alt text][processes]

* [gotop](https://github.com/xxxserxxx/gotop)
* [htop](https://github.com/htop-dev/htop/)
* Special Appearance
    * [buddhasay](https://github.com/luisonthekeyboard/buddhasay)

### VSCode with Tokyo City Theme
![alt text][vscode]

### Happy Holidays All!
![alt text][xsnow]

* [xsnow](https://sourceforge.net/projects/xsnow/) mildly working on wayland

## Credits
- Inspired by and stolen from many creative and amazing people whose names will one day be listed here

[terminals]: https://i.imgur.com/kKKcTOy.png "Terminals"
[applications]: https://i.imgur.com/zhag6dt.png "Applications"
[file_explorer]: https://i.imgur.com/up3KT5l.png "File Explorer"
[launcher]: https://i.imgur.com/59z8Wqb.png "Application Launcher"
[power_script]: https://i.imgur.com/wGZPYHL.png "Power Script"
[xsnow]: https://i.imgur.com/mrZgeH9.png "Happy Holidays!"
[processes]: https://i.imgur.com/Oze3wuX.png "Process Managers"
[vscode]: https://i.imgur.com/MX26He9.png "VSCode - Tokyo City"
[firefox]: https://i.imgur.com/JFYXUbR.png "Firefox"
