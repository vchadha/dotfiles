# . dotfiles

System Configuration Files

My shell, editor and desktop config for macOS and Arch. Settings shared by
every machine live in `common/`, and each machine adds the folders for its OS
and hardware. `install.sh` symlinks them into `~` with
[GNU Stow](https://www.gnu.org/software/stow/).

## Layout

| Folder | Goes on | Contains |
|---|---|---|
| `common/` | every machine | shell, vim, tmux, gotop |
| `macos/` | every Mac | Homebrew, dev toolchains, Colima |
| `arch/` | every Arch machine | sway desktop |
| `host-thinkpad/` | the ThinkPad | monitors, touchpad, kitty, media apps |
| `host-macbookpro-home/` | the home MacBook Pro | game dev tools |
| `profiles/` | | which folders each machine gets |

Each folder mirrors `~`, so `common/.vimrc` is installed as `~/.vimrc`. Everything
is listed in [What's included](#whats-included).

## Install

1. Install the prerequisites:
   - **macOS**: [Homebrew](https://brew.sh), then `brew install stow`
   - **Arch**: `pacman -S git stow zsh vim tmux`
2. Clone it anywhere and install your machine's profile:

   ```sh
   git clone https://github.com/vchadha/dotfiles ~/Developer/dotfiles
   cd ~/Developer/dotfiles
   ./install.sh thinkpad      # or macbookpro-home; --help lists them all
   ```

3. If zsh isn't already your shell: `chsh -s "$(command -v zsh)"`
4. vim-devicons needs a [Nerd Font](https://www.nerdfonts.com) set in your terminal.

### Options

Stow won't overwrite real files. If any file `install.sh` wants to link already
exists, it lists the conflicts and changes nothing. Rerun with an option to
resolve them:

| Command | What it does | Use it when |
|---|---|---|
| `./install.sh <profile>` | Links everything, or lists conflicts and stops | Always start here |
| `./install.sh --backup <profile>` | Moves existing files to `~/.dotfiles-backup/<timestamp>/`, then links | New machine; the repo should win |
| `./install.sh --adopt <profile>` | Moves existing files *into the repo*, then links. `git diff` shows how the machine differed. Keep hunks with `git add -p`, drop them with `git restore -p` | The machine has edits worth merging. Needs a clean working tree, since git is the undo |
| `./install.sh --help` | Prints usage and the list of profiles | |

## Day to day

Installed files are symlinks into this repo, so editing `~/.zshrc` *is* editing
`common/.zshrc`. `dots` runs git in the repo from anywhere:

```sh
dots status
dots diff
dots commit -am "..."
dots pull && ./install.sh <profile>   # bring another machine up to date
```

Re-running `install.sh` is safe. It picks up new files (e.g. after a plugin
update) and prunes links to deleted ones.

There are three ways a change can bypass git:

- **An app creates a new config file.** It's a real file in `~`, not in the
  repo. To track it, move it into the right folder and re-run `install.sh`:

  ```sh
  mv ~/.config/foo/new.conf common/.config/foo/
  ./install.sh <profile>
  ```

- **A program replaces a symlink with a regular file.** This happens with
  programs that save by writing a new file and renaming it over the old one.
  From then on, edits to that file stop reaching the repo.
  - vim (`'backupcopy'` defaults to `auto`) and macOS `sed -i` both leave
    links intact.
  - **To catch it,** re-run `./install.sh <profile>`. A link that became a real
    file shows up as a conflict, and nothing changes. `./install.sh --adopt
    <profile>` then pulls it back into the repo, and `dots diff` shows what
    changed meanwhile.

- **Installers append to your shell config.** See [Gotchas](#gotchas).

## What's included

### `common/` (every machine)

- **zsh**: prompt with git branch (yellow when dirty) and command timing,
  shared history, case-insensitive completion menu. Plugins:
  [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and
  sudo (<kbd>Esc</kbd> <kbd>Esc</kbd> prefixes the line with `sudo`).
- **bash and sh**: same environment and functions as zsh, via `~/.shell/`.
- **Functions**:
  - `dots`: git for this repo
  - `lookup` (and the `blookup`, `pblookup`, `pplookup` variants): grep files matching a name
  - `scratch`: shell in a temp dir that's deleted on exit
  - `subtree` (zsh): pruned `tree`
  - `append_path`, `prepend_path`
- **vim**: [NERDTree](https://github.com/preservim/nerdtree) (+
  [git plugin](https://github.com/Xuyuanp/nerdtree-git-plugin)),
  [vim-devicons](https://github.com/ryanoasis/vim-devicons),
  [tcomment](https://github.com/tomtom/tcomment_vim),
  [goyo](https://github.com/junegunn/goyo.vim).
- **tmux**: prefix <kbd>Ctrl</kbd>+<kbd>a</kbd>, mouse on, copy to the system
  clipboard (the OS folder sets which tool).
- **[gotop](https://github.com/xxxserxxx/gotop)**: config and layout.

### `macos/` (every Mac)

- **Homebrew** environment
- **Toolchains**, each skipped if not installed: Rust, Lean (elan), Bun, .NET,
  nvm, pyenv, opam, SDKMAN, VS Code's `code`
- **[Colima](https://github.com/abiosoft/colima)** as the Docker runtime (`DOCKER_HOST`)
- **`og`**: open the repo's remote in the browser
- tmux copies with `pbcopy`. gotop config is linked into
  `~/Library/Application Support/gotop/`, where macOS gotop looks for it

### `arch/` (every Arch machine)

- **Desktop**: [sway](https://github.com/swaywm/sway),
  [waybar](https://github.com/Alexays/Waybar) (with a media player module),
  [mako](https://github.com/emersion/mako) notifications,
  [rofi](https://github.com/davatorium/rofi) launcher, GTK 3 settings,
  wallpaper and lock screen images
- **Scripts** in `~/.local/bin/scripts/`: lock, idle (lock after 5 min, screen off
  after 10), rofi power menu, slideshow
- **ssh-agent**, started once and shared by every shell
- **Functions**: `update_mirrors` (ranks pacman mirrors), `rsteam`
- tmux copies with `wl-copy`

### `host-thinkpad/`

- **sway `host.conf`**: laptop and 4K monitor layout, lid-close turns off
  the laptop screen, touchpad tap and natural scroll
- **[kitty](https://github.com/kovidgoyal/kitty)** terminal
- **[mpd](https://www.musicpd.org) + [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp)** music
- **[zathura](https://github.com/pwmt/zathura)** PDF viewer
- `bg_changer.sh` (random wallpaper), `battery_status`

### `host-macbookpro-home/`

- Playdate SDK, nom, Unity CLI

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
from the OS folder, and sway includes `~/.config/sway/host.conf` from the host
folder. **Every sway machine needs a `host.conf`.**

## Adding a machine

A profile is a file in `profiles/` named after the machine, listing the folders
it gets on one line:

```sh
$ cat profiles/macbookpro-home
common macos host-macbookpro-home
```

- **Another Mac or Arch box:** add `profiles/<name>` (e.g. `common macos`). Add a
  `host-<name>/` folder only if it needs something the others don't.
- **A new OS (e.g. Debian):** add a `<os>/` folder that provides
  `.shell/os/{env,interactive}` and `.tmux.clipboard.conf`. If it's headless,
  that's the time to split sway out of `arch/` into its own folder.

Either way, add it to [What's included](#whats-included).

## Gotchas

- **Installers that append to `~/.zshrc` (nvm, bun, opam, …)** are now editing
  `common/.zshrc` in this repo through the symlink. It shows up in `git status`.
  Move the lines into `macos/`, the host folder, or `local/`.
- **Two folders can't own the same file.** That's what stops `macos` and
  `arch` from being installed together.
