# dotfiles

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

`profiles/` lists which packages each machine gets. Files in each package are
linked to the same path under `~`, so `common/.vimrc` becomes `~/.vimrc`. The
full list of configs is in [What's included](#whats-included).

`hooks/pre-commit` stops you from committing secrets. `install.sh` turns it on.

## Requirements

- **macOS**
  - git: `xcode-select --install` (Homebrew's installer also does this)
  - [Homebrew](https://brew.sh)
  - GNU Stow and tmux: `brew install stow tmux`
- **Arch**
  - `pacman -S git stow zsh vim tmux`
- **zsh as your login shell**: already the default on macOS. On Arch,
  `chsh -s /usr/bin/zsh`
- **A [Nerd Font](https://www.nerdfonts.com)** set in your terminal, for the
  icons in vim, tmux's status bar and Waybar

`install.sh` links config; it doesn't install apps. Config for an app you
don't have is linked but never read, and shell setup for a missing tool (nvm,
uv, Colima, …) is skipped.

## Install

Clone the repo anywhere and install your machine's profile
(`./install.sh --help` lists them). On a Mac with nothing extra, that's
`macbookpro-work`:

```sh
git clone https://github.com/vchadha/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install.sh <profile>
```

### Flags

Stow won't overwrite real files. If any file `install.sh` wants to link already
exists, it lists the conflicts and changes nothing. Rerun with a flag to
resolve them:

| Flag | What it does | Use it when |
|---|---|---|
| (none) | Links everything, or lists conflicts and stops | Try this first |
| `--backup` | Moves existing files to `~/.dotfiles-backup/<timestamp>/`, then links | The existing files can go |
| `--adopt` | Moves existing files *into the repo*, then links. Review with `git diff` | The machine has edits worth keeping |
| `--help` | Prints usage and the list of profiles | |

`--adopt` needs a clean working tree, because git is how you undo it. Then
`git add -p` keeps the changes you want and `git restore -p` drops the rest.

Once installed, <kbd>Tab</kbd> in zsh completes the flags and profile names,
for both `./install.sh` and `dots install`.

### Uninstall

From the repo, remove the links, then copy back a backup if you made one:

```sh
stow -D $(cat profiles/<profile>)
cp -R ~/.dotfiles-backup/<timestamp>/. ~
```

## Where settings go

Shell config loads in layers, most general first: `common`, then `os/`,
`host/` and `local/`.

- **`os/`** comes from `macos/` or `arch/`: things true of every machine of that kind.
- **`host/`** comes from `host-<machine>/`: things only that machine has.
- **`local/`** is **never tracked**: secrets and one-off tweaks. Put a token
  in `local/env` if scripts need it, `local/interactive` if only your terminal does.

Each layer has two files, in `~/.shell/` for `common` and `~/.shell/<layer>/`
for the rest (zsh-only bits go in `~/.zsh/` the same way):

- **`env`**: environment variables and `PATH`. Every shell reads it, scripts
  included, so it must be plain `sh` and print nothing.
- **`interactive`**: aliases, functions, completions, slow tool setup.
  Terminals only.

The editor is vim. To use a different one on one machine, put this in
`~/.shell/local/env`:

```sh
export EDITOR=nano
```

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

Re-running `dots install` is safe. It links new files and removes links to
deleted ones. The exception is a deleted *folder*: its links stay behind,
broken, and you delete them by hand. `find -L ~/.vim/pack -type l` lists the
broken links in a folder.

If a change affects something the [wiki](https://github.com/vchadha/dotfiles/wiki)
describes, update it too.

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
Move them into the right layer's file (see [Where settings go](#where-settings-go)),
e.g. `macos/.shell/os/env` or `~/.shell/local/interactive`.

## What's included

The [Features](https://github.com/vchadha/dotfiles/wiki/Features) wiki page
has the details, keybindings included.

### `common/` (every machine)

- **zsh**: git-aware prompt, shared history, completion,
  [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), sudo plugin
- **bash**: same environment and functions as zsh, minus the zsh-only ones;
  **sh** gets the environment only
- **Functions**: `dots`, `lookup`, `scratch`, `subtree` (needs `tree`),
  `append_path`, `prepend_path`
- **[uv](https://docs.astral.sh/uv/)** completion, for Python versions and environments
- **vim**: [NERDTree](https://github.com/preservim/nerdtree),
  [vim-devicons](https://github.com/ryanoasis/vim-devicons),
  [tcomment](https://github.com/tomtom/tcomment_vim),
  [goyo](https://github.com/junegunn/goyo.vim)
- **tmux**
- **[gotop](https://github.com/xxxserxxx/gotop)**
- **Claude Code**: global `CLAUDE.md` (the rest of `~/.claude` is never tracked)

### `macos/` (every Mac)

- **Homebrew**
- **Toolchains**: Rust, Lean, Bun, .NET, nvm, opam, SDKMAN, VS Code CLI
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
4. Add it to [What's included](#whats-included) and the wiki's Features page.

Two packages in one profile can't contain the same file; Stow refuses to
install it. That also stops `macos` and `arch` from going in one profile.

## Tests

```sh
tests/run.sh
```

Run it before pushing; it takes about 15 seconds. The tests use throwaway
home folders, so your own is never touched. Each suite also runs on its own,
e.g. `tests/test-lint.sh`.

The tests need `git`, `stow`, `zsh` and `python3`. If `dash`, `vim` or `tmux`
is missing, its checks are skipped and listed as skipped.

| Suite | Checks |
|---|---|
| `test-install-args.sh` | How `install.sh` handles what people type: flags in any order, `--help` next to mistakes, bad profile names |
| `test-install-behavior.sh` | What it does to a home folder: conflicts, `--backup`, `--adopt`, re-runs, every profile linking cleanly |
| `test-startup.sh` | Each profile for this OS, in a fresh home: every shell starts without errors or output, with the right `PATH`; zsh's keys and git prompt, `dots`, the PATH helpers, vim and tmux work as documented |
| `test-lint.sh` | Shell syntax in every shell that reads a file, the Waybar config parses, no retired Nerd Font icons, only scripts are executable, `.gitignore` catches credentials, nothing tracked looks like a secret |

The startup suite only covers the profiles for the OS it runs on.

## Credits

Inspired by and stolen from many creative and amazing people whose names will
one day be listed here. Borrowed files:

- `common/.zsh/plugins/sudo/` is from [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)
- `arch/.config/waybar/modules/mediaplayer.py` is from [Waybar](https://github.com/Alexays/Waybar)

Both are MIT-licensed; the licences are in `LICENSES/`.
