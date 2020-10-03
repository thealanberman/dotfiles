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
# set -o xtrace # set -x

# get current working directory
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

append_inputrc()
{
  if ! grep -q "history-search-forward" "${HOME}/.inputrc"; then
    cp "${CWD}/.inputrc" "${HOME}"
  fi
}

macos_symlinks()
{
  echo "[ Making Symlinks ]"
  mkdir -p \
    "${HOME}/Library/Application Support/navi/cheats"
    "${HOME}/.bash-it/custom/"

  ln -fs "${CWD}/my.cheat" "${HOME}/Library/Application Support/navi/cheats/"
  ln -fs "${CWD}/customizations.bash" "${HOME}/.bash-it/custom/"
  ln -fs "${CWD}/nuna.bash" "${HOME}/.bash-it/custom/"
}

linux_symlinks()
{
  echo "[ Making Symlinks ]"
  mkdir -p \
    "${HOME}/.local/share/navi/cheats" \
    "${HOME}/.bash-it/custom/"
  
  ln -fs "${CWD}/my.cheat" "${HOME}/.local/share/navi/cheats/"
  ln -fs "${CWD}/customizations.bash" "${HOME}/.bash-it/custom/"
  ln -fs "${CWD}/nuna.bash" "${HOME}/.bash-it/custom/"
}

configure_vim()
{
  echo "[ Configuring Vim ]"
  [[ -f "${HOME}/.vimrc" ]] && return
  mkdir -p "${HOME}/.vim/pack/default/start"
  git clone https://github.com/morhetz/gruvbox.git "${HOME}/.vim/pack/default/start/gruvbox"
  git clone https://github.com/sheerun/vim-polyglot "${HOME}/.vim/pack/default/start/vim-polyglot"
  ln -s "${CWD}/.vimrc" "${HOME}/.vimrc"
}

install_bashit() 
{
  echo "[ Installing Bash-It ]"
  # can't install bash-it without git
  git --version || return 
  read -e -s -p "Install Bash-it [y/N]? " -n 1 -r
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    if [[ -d "${HOME}/.bash-it" ]]; then
      pushd "${HOME}/.bash-it"
      git pull
      popd
    else
      /usr/bin/git clone --depth=1 https://github.com/Bash-it/bash-it.git "${HOME}/.bash-it"
      eval "${HOME}/.bash-it/install.sh" --silent
    fi
  fi
}

install_homebrew()
{
  echo "[ Installing Homebrew ]"
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

get_latest_version()
{
  curl --silent "${1}/releases/latest" | grep -Eo '[0-9]+.[0-9]+.[0-9]+'
}

install_linux_apps()
{
  echo "[ Installing apps ]"

  # golang apps
  mkdir -p "${HOME}/code/go"
  export GOPATH="${HOME}/code/go"
  go version >/dev/null || return
  PATH="${PATH}:${HOME}/code/go/bin"
  which awless || go get -u github.com/wallix/awless
  which lazydocker || go get -u github.com/jesseduffield/lazydocker

  local version
  which bat || {
    version=$(get_latest_version https://github.com/sharkdp/bat)
    curl -sL "https://github.com/sharkdp/bat/releases/download/v${version}/bat-musl_${version}_amd64.deb" -o /tmp/bat.deb
    sudo dpkg -i /tmp/bat.deb
  }
  
  which fd || {
    version=$(get_latest_version https://github.com/sharkdp/fd)
    curl -sL "https://github.com/sharkdp/fd/releases/download/v${version}/fd-musl_${version}_amd64.deb" -o /tmp/fd.deb
    sudo dpkg -i /tmp/fd.deb
  }

  which rg || {
    version=$(get_latest_version https://github.com/BurntSushi/ripgrep)
    curl -sL "https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep_${version}_amd64.deb" -o /tmp/rg.deb
    sudo dpkg -i /tmp/rg.deb
  }

  which sd || {
    version=$(get_latest_version https://github.com/chmln/sd)
    sudo curl -sL "https://github.com/chmln/sd/releases/download/v${version}/sd-v${version}-x86_64-unknown-linux-musl" -o /usr/local/bin/sd
    sudo chmod +x /usr/local/bin/sd
  }
  
  which navi || {
    curl -sL https://raw.githubusercontent.com/denisidoro/navi/master/scripts/install | sudo /bin/bash
    navi repo add denisidoro/navi-tldr-pages
  }
}

set_bashit_theme()
{
  sd 'bobby' 'powerline' ~/.bashrc 2>/dev/null
  sd 'bobby' 'powerline' ~/.bash_profile 2>/dev/null
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
    set_bashit_theme
    source ~/.bash_profile
    ;;
  Linux)
    append_inputrc
    sudo apt-get update
    sudo apt-get install \
      git \
      docker \
      docker-compose \
      fzf \
      shellcheck \
      golang-go \
      tmux
    install_bashit
    configure_vim
    linux_symlinks
    install_linux_apps
    set_bashit_theme
    source ~/.bashrc
    ;;
  *)
    printf "ERROR: uname reports this OS is %s. Exiting." "$(uname)"
  ;;
esac
