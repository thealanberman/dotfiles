#!/usr/bin/env bash

case $(uname) in 
  Darwin)
    xcode-select --install
    install_homebrew
    install_brew_apps
    setup_note
    return
    ;;
  Linux)
    sudo apt-get update
    sudo apt-get install git
    setup_note
    return
    ;;
  *)
    echo "ERROR: uname reports this OS is not Darwin or Linux. Exiting."
  ;;
esac


# can't install bash-it without git
if [[ $(git --version) ]]; then
  install_bashit
else
  echo "git not found."
fi


install_bashit() 
{
  read -e -s -p "Install Bash-it [y/N]? " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    /usr/bin/git clone --depth=1 https://github.com/Bash-it/bash-it.git "${HOME}/.bash-it"
    eval "${HOME}/.bash-it/install.sh --silent --no-modify-config"
  fi
}


install_homebrew()
{
  read -e -s -p "Install Homebrew [y/N]? " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}


install_brew_apps()
{
  read -e -s -p "Install Homebrew apps [y/N]? " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew install \
    awless \
    awscli \
    bash \
    dc3dd \
    dockutil \
    ffmpeg \
    git \
    grep \
    jq \
    openssh \
    openssl \
    pipenv \
    psgrep \
    python \
    ripgrep \
    ruby \
    shellcheck \
    thefuck \
    tree \
    vim \
    wget 
  fi
}
setup_note() {
  local CWD
  CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  [[ -f "${CWD}/note" ]] && { ln -s "${CWD}/note" /usr/local/bin/; }
}
