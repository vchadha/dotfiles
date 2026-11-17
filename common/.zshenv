# Source zsh env -- except in login shells, which get it from .zprofile
# instead. zsh reads the system's /etc/zprofile between this file and
# .zprofile, and on macOS that runs path_helper, which moves everything env
# put on PATH behind /usr/bin (so Apple's python3 beats Homebrew's).
[[ -o login ]] || source $HOME/.zsh/env
