#!/usr/bin/env zsh

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
CWD=${0:a:h}

append_inputrc() {
  if ! grep -q "history-search-forward" "${HOME}/.inputrc"; then
    cp "${CWD}/.inputrc" "${HOME}"
  fi
}

make_symlinks() {
  echo "[ Making Symlinks ]"
  ln -fs "${CWD}/.inputrc" "${HOME}/"
  ln -fs "${CWD}/.tmux.conf" "${HOME}/"
  ln -fs "${CWD}/.vimrc" "${HOME}/"
  ln -fs "${CWD}/.zshrc" "${HOME}/"
  ln -fs "${CWD}/.p10k.zsh" "${HOME}/"
  ln -fs "${CWD}/prompty" "/usr/local/bin/"
  ln -fs "${CWD}/.gitconfig" "${HOME}/"
  ln -fs "${CWD}/.global_gitignore" "${HOME}/"
}

configure_vim() {
  echo "[ Configuring Vim ]"
  mkdir -p "${HOME}/.vim/pack/default/start"
  git clone https://github.com/morhetz/gruvbox.git "${HOME}/.vim/pack/default/start/gruvbox"
  git clone https://github.com/sheerun/vim-polyglot "${HOME}/.vim/pack/default/start/vim-polyglot"
}

install_homebrew() {
  echo "[ Installing Homebrew ]"
  read -e -s -p "Install Homebrew [y/N]? " -n 1 -r
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}

install_brew_apps() {
  read -e -s -p "Install Homebrew apps [y/N]? " -n 1 -r
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    brew install \
      bat \
      dc3dd \
      duf \
      git-delta \
      fd \
      ffmpeg \
      git \
      golang \
      highlight \
      jq \
      mcfly \
      mtr \
      psgrep \
      pv \
      python \
      ripgrep \
      tfenv \
      tldr \
      tmux \
      tree \
      vim \
      wget \
      yt-dlp
  fi
}

get_latest_version() {
  curl --silent "${1}/releases/latest" | grep -Eo '[0-9]+.[0-9]+.[0-9]+'
}

install_linux_apps() {
  echo "[ Installing apps ]"

  # golang apps
  mkdir -p "${HOME}/code/go"
  export GOPATH="${HOME}/code/go"
  go version >/dev/null || return
  PATH="${PATH}:${HOME}/code/go/bin"

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
}

case $(uname) in
Darwin)
  append_inputrc
  xcode-select --install
  install_homebrew
  install_brew_apps
  configure_vim
  make_symlinks
  cat <<EOF >>"${HOME}/.zshrc"
export HISTCONTROL=ignoreboth:erasedups
source ${CWD}/customizations.zsh
EOF
  echo "REMEMBER: source ~/.zshrc"
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
  cat <<EOF >>"${HOME}/.zshrc"
export HISTCONTROL=ignoreboth:erasedups
source ${CWD}/customizations.zsh
EOF
  echo "REMEMBER: source ~/.zshrc"
  ;;
*)
  printf "ERROR: uname reports this OS is %s. Exiting." "$(uname)"
  ;;
esac
