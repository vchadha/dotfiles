# . dotfiles

System Configuration Files

My shell and app configs for my machines. Each top-level folder is a Stow
*package*: `common/` holds settings shared by every machine, and each machine
adds packages for its OS and hardware. `install.sh` symlinks them into `~/`
with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout

| Package | Goes on | Contains |
|---|---|---|
| `common/` | every machine | shell, vim, tmux |
| `macos/` | every Mac | Homebrew, dev toolchains |
| `arch/` | every Arch machine | sway desktop |
| `host-thinkpad/` | my ThinkPad | touchpad, media apps |
| `host-macbookpro-home/` | my personal MacBook Pro | game dev tools |
| `profiles/` | | which packages each machine gets |

Files in each package are linked to the same path under `~`, so
`common/.vimrc` becomes `~/.vimrc`. The full list of configs is in
[What's included](#whats-included).

## Requirements
- **macOS**
  - [Homebrew](https://brew.sh)
  - GNU Stow and tmux: `brew install stow tmux`
- **Arch**
  - `pacman -S git stow zsh vim tmux`
- **zsh as your login shell**: already the default on macOS. On Arch,
  `chsh -s /usr/bin/zsh`
- **A [Nerd Font](https://www.nerdfonts.com)** set in your terminal, for
  vim-devicons' file icons

`install.sh` links config; it doesn't install apps. Config for an app you
don't have is linked but never read, and shell setup for a missing tool (nvm,
pyenv, Colima, …) is skipped.

## Install

Clone the repo anywhere and install your machine's profile
(`./install.sh --help` lists them):

```sh
git clone https://github.com/vchadha/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install.sh thinkpad
```

### Flags

Stow won't overwrite real files. If any file `install.sh` wants to link already
exists, it lists the conflicts and changes nothing. Rerun with a flag to
resolve them:

| Flag | What it does | Use it when |
|---|---|---|
| (none) | Links everything, or lists conflicts and stops | Always start here |
| `--backup` | Moves existing files to `~/.dotfiles-backup/<timestamp>/`, then links | New machine setup |
| `--adopt` | Moves existing files *into the repo*, then links. Review with `git diff` | The machine has edits worth keeping |
| `--help` | Prints usage and the list of profiles | |

`--adopt` needs a clean working tree, since git is the undo. `git add -p` steps
through each change so you can keep the ones you want, and `git restore -p`
drops the rest.

Once installed, <kbd>Tab</kbd> in zsh completes the flags and profile names,
for both `./install.sh` and `dots install`.

## Making changes

Installed files are symlinks into this repo, so editing `~/.zshrc` *is* editing
`common/.zshrc`. `dots` runs git in the repo from anywhere, and
`dots install` runs `install.sh` (same flags):

```sh
dots status
dots diff
dots commit -am "..."
dots pull && dots install <profile>   # get upstream changes
```

Re-running `dots install` is safe. It links new files (e.g. after a plugin
update) and removes links to files deleted from the repo. If you delete a
whole folder from a package, though, its links stay behind in `~`, broken.
Delete those by hand.

There are two ways a change can bypass git:

- **An app creates a new config file.** It's a real file in `~`, not in the
  repo. To track it, move it into the right package and re-run the install:

  ```sh
  mv ~/.config/foo/new.conf ~/Developer/dotfiles/common/.config/foo/
  dots install <profile>
  ```

- **A program replaces a symlink with a regular file.** This happens with
  programs that save by writing a new file and renaming it over the old one.
  From then on, edits to that file stop reaching the repo.

  To find these, re-run `dots install <profile>`. It reports each one as a
  conflict and changes nothing. Then `dots install --adopt <profile>` moves the
  files back into the repo, and `dots diff` shows what changed.

### Installers that edit your shell config

nvm, bun, opam and the like add lines to `~/.zshrc`, which is `common/.zshrc`
in this repo, so every machine would get them. They show up in `dots status`.
Move them into `macos/`, the host package, or `local/`.

## What's included

The [Features](https://github.com/vchadha/dotfiles/wiki/Features) wiki page
has the details, keybindings included.

### `common/` (every machine)

- **zsh**: git-aware prompt, shared history, completion,
  [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), sudo plugin
- **bash and sh**: same environment and functions as zsh
- **Functions**: `dots`, `lookup`, `scratch`, `subtree`, `append_path`, `prepend_path`
- **vim**: [NERDTree](https://github.com/preservim/nerdtree),
  [vim-devicons](https://github.com/ryanoasis/vim-devicons),
  [tcomment](https://github.com/tomtom/tcomment_vim),
  [goyo](https://github.com/junegunn/goyo.vim)
- **tmux**
- **[gotop](https://github.com/xxxserxxx/gotop)**

### `macos/` (every Mac)

- **Homebrew**
- **Toolchains**: Rust, Lean, Bun, .NET, nvm, pyenv, opam, SDKMAN, VS Code CLI
- **[Colima](https://github.com/abiosoft/colima)** as the Docker runtime
- **Functions**: `og`

### `arch/` (every Arch machine)

- **Desktop**: [sway](https://github.com/swaywm/sway),
  [waybar](https://github.com/Alexays/Waybar),
  [mako](https://github.com/emersion/mako),
  [rofi](https://github.com/davatorium/rofi), GTK 3
- **Scripts**: lock, idle, power menu, slideshow
- **ssh-agent**
- **Functions**: `update_mirrors`, `rsteam`

### `host-thinkpad/`

- **sway**: monitors, touchpad
- **[kitty](https://github.com/kovidgoyal/kitty)**,
  **[mpd](https://www.musicpd.org) + [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp)**,
  **[zathura](https://github.com/pwmt/zathura)**
- **Extras**: `bg_changer.sh` script, `battery_status` alias

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

## Adding a machine

1. Add `profiles/<name>`, listing the packages the machine gets on one line:

   ```sh
   $ cat profiles/macbookpro-home
   common macos host-macbookpro-home
   ```

2. If the machine needs something no other machine does, add a
   `host-<name>/` package and list it in the profile.
3. If it runs a new OS (e.g. Debian), add a `<os>/` package with
   `.shell/os/{env,interactive}`.
4. Add it to [What's included](#whats-included).

Two packages in one profile can't contain the same file; Stow refuses to
install it. This prevents `macos` and `arch` from being installed together.

## Tests

`tests/install-args.sh` checks how `install.sh` handles what people type
(flags in any order, `--help` next to mistakes, bad profile names), each case
against a throwaway home folder. Run it after changing `install.sh`.

## Credits

Inspired by and stolen from many creative and amazing people whose names will
one day be listed here.
