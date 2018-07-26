#!/usr/bin/env bash

# make sure we have git
[[ -f "/usr/bin/git" ]] && { echo "git found. moving on..."; }|| { echo "git not installed."; exit; }

read -e -s -p "Install Bash-it [y/N]? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  /usr/bin/git clone --depth=1 https://github.com/Bash-it/bash-it.git ${HOME}/.bash-it
  eval "${HOME}/.bash-it/install.sh --silent --no-modify-config"
fi

if [[ $(uname) == "Darwin" ]]; then

  read -e -s -p "Install Homebrew [y/N]? " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

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

fi

echo "Be sure to 'source ~/.bash_profile' to have your settings take effect."
echo "Then './configure-bash-it.sh' to customize your shell."
