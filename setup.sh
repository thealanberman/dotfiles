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

configure_vim()
{
  mkdir -p ~/.vim/pack/default/start
  git clone https://github.com/morhetz/gruvbox.git ~/.vim/pack/default/start/gruvbox
  git clone https://github.com/sheerun/vim-polyglot ~/.vim/pack/default/start/vim-polyglot
  ln -s "${CWD}"/.vimrc ~/.vimrc
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
    awscli \
    bash \
    bat \
    dc3dd \
    dockutil \
    fd \
    ffmpeg \
    fselect \
    git \
    grep \
    highlight \
    httpie \
    lazydocker \
    lsd \
    jq \
    micro \
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
    sipcalc \
    thefuck \
    tmux \
    tree \
    usql \
    vim \
    wget \
    youtube-dl \
    yq
  fi
}

case $(uname) in 
  Darwin)
    append_inputrc
    xcode-select --install
    install_homebrew
    install_brew_apps
    install_bashit
    configure_vim
    ;;
  Linux)
    append_inputrc
    sudo apt-get update
    sudo apt-get install git
    install_bashit
    configure_vim
    ;;
  *)
    echo "ERROR: uname reports this OS is not Darwin or Linux. Exiting."
  ;;
esac
