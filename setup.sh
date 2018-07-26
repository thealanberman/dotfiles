#!/usr/bin/env bash

# make sure we have git
[[ $(command -v git) ]] && { install_bashit; } || { echo "git not installed."; }
# TODO 
# fix this case statement to handle Linux or Darwin
# case foo in $(uname)
#   "Darwin")
#     install_homebrew
#     install_brew_apps
#   *)
# fi


install_bashit() 
{
  read -e -s -p "Install Bash-it [y/N]? " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    /usr/bin/git clone --depth=1 https://github.com/Bash-it/bash-it.git ${HOME}/.bash-it
    eval "${HOME}/.bash-it/install.sh --silent --no-modify-config"
  fi
}

install_git()
{
  sudo apt-get update && sudo apt-get install git
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
