#!/usr/bin/env bash

# Exit on error. Append "|| true" if you expect an error.
# set -o errexit # set -e
# Exit on error inside any functions or subshells.
# set -o errtrace # set -E
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

make_symlinks()
{
  echo "[ Making Symlinks ]"
  ln -fs "${CWD}/.inputrc" "${HOME}/"
  ln -fs "${CWD}/.tmux.conf" "${HOME}/"
  ln -s "${CWD}/.vimrc" "${HOME}/"
  ln -s "${CWD}/prompty" "/usr/local/bin/"
}

configure_vim()
{
  echo "[ Configuring Vim ]"
  mkdir -p "${HOME}/.vim/pack/default/start"
  git clone https://github.com/morhetz/gruvbox.git "${HOME}/.vim/pack/default/start/gruvbox"
  git clone https://github.com/sheerun/vim-polyglot "${HOME}/.vim/pack/default/start/vim-polyglot"
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
    mcfly \
    mtr \
    openssh \
    openssl \
    pipx \
    pipenv \
    psgrep \
    pv \
    python \
    ripgrep \
    ruby \
    shellcheck \
    starship \
    tfenv \
    tldr \
    tmux \
    tree \
    vim \
    wget \
    youtube-dl \
    yq
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

  which starship || {
    sh -c "$(curl -fsSL https://starship.rs/install.sh)"
  }
}

case $(uname) in 
  Darwin)
    append_inputrc
    xcode-select --install
    install_homebrew
    install_brew_apps
    configure_vim
    make_symlinks
    echo "export BASH_SILENCE_DEPRECATION_WARNING=1" >> "${HOME}/.bash_profile"
    echo "for f in ${CWD}/*.bash; do source \${f}; done" >> "${HOME}/.bash_profile"
    echo "export STARSHIP_CONFIG=${CWD}/starship.toml" >> "${HOME}/.bash_profile"
    echo "eval \"\$(starship init bash)\"" >> "${HOME}/.bash_profile"
    echo "REMEMBER: source ~/.bash_profile"
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
    configure_vim
    make_symlinks
    install_linux_apps
    echo "for f in ${CWD}/*.bash; do source \${f}; done" >> "${HOME}/.bashrc"
    echo "export STARSHIP_CONFIG=${CWD}/starship.toml" >> "${HOME}/.bashrc"
    echo "eval \"\$(starship init bash)\"" >> "${HOME}/.bashrc"
    echo "REMEMBER: source ~/.bashrc"
    ;;
  *)
    printf "ERROR: uname reports this OS is %s. Exiting." "$(uname)"
  ;;
esac
