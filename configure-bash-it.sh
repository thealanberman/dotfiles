#!/usr/bin/env bash

# get current working directory
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Bash-it check
if [[ -z "$BASH_IT" ]] || [[ ! -d "$BASH_IT" ]]; then
  echo "Bash-it not detected. --> https://github.com/Bash-it/";
  exit;
fi


echo "Symlinking ${CWD}/*.bash to ${BASH_IT}/custom/ ..."
ln -v -s ${CWD}/*.bash ${BASH_IT}/custom

echo "Enabling your aliases, plugins, and completions..."
function enable() {
  if [[ $1 == "plugin" ]]; then
    ln -v -s "${BASH_IT}/${1}s/available/${2}.${1}.bash" "${BASH_IT}/${1}s/enabled"
  else
    ln -v -s "${BASH_IT}/${1}/available/${2}.${1}.bash" "${BASH_IT}/${1}/enabled"
  fi
}

#######################
# UNCOMMENT TO ENABLE #
#######################
# enable aliases ag
# enable aliases ansible
# enable aliases apt
# enable aliases atom
# enable aliases bundler
# enable aliases clipboard
# enable aliases docker
# enable aliases emacs
# enable aliases fuck
enable aliases general
enable aliases git
# enable aliases gitsvn
# enable aliases heroku
# enable aliases hg
enable aliases homebrew-cask
enable aliases homebrew
# enable aliases jitsu
# enable aliases laravel
# enable aliases maven
enable aliases osx
# enable aliases rails
# enable aliases svn
# enable aliases textmate
# enable aliases tmux
# enable aliases todo.txt-cli
# enable aliases vagrant
# enable aliases vim

enable plugin alias-completion
# enable plugin aws
enable plugin base
enable plugin battery
# enable plugin boot2docker
# enable plugin browser
# enable plugin chruby-auto
# enable plugin chruby
# enable plugin dirs
# enable plugin docker-machine
# enable plugin docker
# enable plugin explain
enable plugin extract
# enable plugin fasd
# enable plugin fzf
# enable plugin gh
# enable plugin gif
# enable plugin git-subrepo
enable plugin git
# enable plugin hg
enable plugin history
# enable plugin hub
# enable plugin java
# enable plugin javascript
# enable plugin jekyll
# enable plugin jenv
# enable plugin latex
# enable plugin less-pretty-cat
# enable plugin nginx
# enable plugin node
# enable plugin nvm
# enable plugin osx-timemachine
enable plugin osx
# enable plugin percol
# enable plugin pipsi
# enable plugin postgres
# enable plugin projects
# enable plugin proxy
# enable plugin pyenv
# enable plugin python
# enable plugin rbenv
# enable plugin ruby
# enable plugin rvm
# enable plugin sdkman
# enable plugin ssh
# enable plugin subversion
# enable plugin textmate
# enable plugin tmux
# enable plugin tmuxinator
# enable plugin todo
# enable plugin virtualenv
# enable plugin visual-studio-code
# enable plugin xterm
# enable plugin z
# enable plugin z_autoenv

# enable completion awscli
enable completion bash-it
enable completion brew
# enable completion bundler
# enable completion capistrano
# enable completion conda
enable completion defaults
# enable completion dirs
# enable completion django
# enable completion docker
# enable completion drush
# enable completion fabric
enable completion gem
# enable completion gh
enable completion git
# enable completion git_flow
# enable completion git_flow_avh
# enable completion gradle
# enable completion grunt
# enable completion gulp
# enable completion homesick
# enable completion hub
# enable completion jboss7
# enable completion maven
# enable completion npm
# enable completion packer
enable completion pip
# enable completion projects
# enable completion rake
# enable completion salt
# enable completion sdkman
enable completion ssh
# enable completion svn
enable completion system
# enable completion terraform
# enable completion test_kitchen
# enable completion tmux
# enable completion todo
# enable completion vagrant
# enable completion virtualbox

echo "Bash-it customized!"
