#!/usr/bin/env bash

case $(uname) in 
  Darwin)
    append_inputrc
    configure_vim
    xcode-select --install
    install_homebrew
    install_brew_apps
    ;;
  Linux)
    append_inputrc
    configure_vim
    sudo apt-get update
    sudo apt-get install git
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
  ln -s .vimrc ~/.vimrc
}

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

