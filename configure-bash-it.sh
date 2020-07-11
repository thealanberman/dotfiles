#!/usr/bin/env bash

# get current working directory
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Bash-it check
if [[ -z "$BASH_IT" ]] || [[ ! -d "$BASH_IT" ]]; then
  echo "Bash-it not detected. --> https://github.com/Bash-it/";
  exit;
fi


echo "Symlinking ${CWD}/*.bash to ${BASH_IT}/custom/"
ln -v -s "${CWD}"/*.bash "${BASH_IT}"/custom 2>/dev/null


echo "Enabling your aliases, plugins, and completions"
function enable() {
  if [[ $1 == "plugin" ]]; then
    ln -v -s "${BASH_IT}/${1}s/available/${2}.${1}.bash" "${BASH_IT}/${1}s/enabled" 2>/dev/null
  else
    ln -v -s "${BASH_IT}/${1}/available/${2}.${1}.bash" "${BASH_IT}/${1}/enabled" 2>/dev/null
  fi
}

# macOS specific stuff
if [[ $(uname) == "Darwin" ]]; then
  enable aliases homebrew-cask
  enable aliases homebrew
  enable aliases osx
  enable plugin osx
  enable plugin battery
  enable completion brew
  enable completion defaults
fi

enable aliases general
enable aliases git
enable plugin alias-completion
enable plugin base
enable plugin extract
enable plugin git
enable plugin history
enable completion bash-it
enable completion gem
enable completion git
enable completion pip
enable completion ssh
enable completion system

echo "Bash-it customized!"
