#!/usr/bin/env bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit # set -e
# Exit on error inside any functions or subshells.
set -o errtrace # set -E
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset # set -u
# Catch the error in case 1st command fails but piped command succeeds
set -o pipefail
# Turn on traces, useful while debugging
set -o xtrace # set -x

# get current working directory
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

append_inputrc()
{
  if ! grep "completion-ignore-case" ~/.inputrc &> /dev/null; then
    printf "set completion-ignore-case On" >> ~/.inputrc
  fi
}

macos_symlinks()
{
  ln -s "${CWD}/my.cheat" "${HOME}/Library/Application Support/navi/cheats/"
}

linux_symlinks()
{
  ln -s "${CWD}/my.cheat" "${HOME}/.local/share/navi/cheats/"
}

configure_vim()
{
  [[ -f "${HOME}/.vimrc" ]] && { return 1; }
  mkdir -p "${HOME}/.vim/pack/default/start"
  git clone https://github.com/morhetz/gruvbox.git "${HOME}/.vim/pack/default/start/gruvbox"
  git clone https://github.com/sheerun/vim-polyglot "${HOME}/.vim/pack/default/start/vim-polyglot"
  ln -s "${CWD}/.vimrc" "${HOME}/.vimrc"
}

install_bashit() 
{
  # can't install bash-it without git
  git --version || return 
  read -e -s -p "Install Bash-it [y/N]? " -n 1 -r
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    /usr/bin/git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash-it
    eval ~/.bash-it/install.sh --silent --no-modify-config
  fi
}

install_homebrew()
{
  read -e -s -p "Install Homebrew [y/N]? " -n 1 -r
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}

install_brew_apps()
{
  read -e -s -p "Install Homebrew apps [y/N]? " -n 1 -r
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    brew install \
    awless \
    bash \
    bat \
    dc3dd \
    dockutil \
    fd \
    ffmpeg \
    git \
    golang \
    grep \
    highlight \
    lazydocker \
    jq \
    mtr \
    navi \
    openssh \
    openssl \
    pipx \
    pipenv \
    psgrep \
    pv \
    python \
    ripgrep \
    ruby \
    sd \
    shellcheck \
    tfenv \
    thefuck \
    tmux \
    tree \
    vim \
    wget \
    youtube-dl \
    yq \
    z
  fi
}


install_linux_apps()
{
  # golang apps
  go version || return
  go get -u github.com/wallix/awless
  go get -u github.com/jesseduffield/lazydocker

  # rust (cargo) apps
  cargo version || return
  cargo install bat
  cargo install fd-find
  cargo install navi
  cargo install ripgrep
  cargo install sd
}

case $(uname) in 
  Darwin)
    append_inputrc
    xcode-select --install
    install_homebrew
    install_brew_apps
    install_bashit
    configure_vim
    macos_symlinks
    ;;
  Linux)
    append_inputrc
    sudo apt-get update
    sudo apt-get install \
      git \
      docker \
      docker-compose \
      shellcheck \
      golang-go \
      cargo \
      tmux
    install_bashit
    configure_vim
    install_linux_apps
    linux_symlinks
    ;;
  *)
    printf "ERROR: uname reports this OS is %s. Exiting." $(uname)
  ;;
esac
