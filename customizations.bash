#!/usr/bin/env bash

[[ $(command -v code) ]] && \
export EDITOR=$(command -v code) || \
export EDITOR=$(command -v vim)
SELF=$(basename "${BASH_SOURCE}")

# ALIASES

alias l='ls -AGhlF'
alias ll='l'
alias aliases="${EDITOR} ${BASH_IT}/custom/${SELF}"
alias customize='aliases'
alias functions='aliases'
alias dev='cd ~/code'
alias cd..='cd ..'
alias df='df -H'
alias sshconfig="${EDITOR} ${HOME}/.ssh/config"
eval $(thefuck --alias)

# FUNCTIONS

dmg() {
    if [[ -d ${1} ]] && [[ -d ${2} ]]; then
        VOL=$(basename "${1}")
        hdiutil create -fs HFS+ -volname "${VOL}" -srcfolder "${1}" "${2}"/"${VOL}"
    else
        echo "Usage: dmg <source folder> <output folder>"
    fi
}


ff() {
    if [[ -z "${1}" ]]; then
        printf "Usage:\\n  Please specify a search term. use * for wildcards."
        echo "Example: ff *.txt"
    else
        find . -iname "${1}" 2>/dev/null
    fi
}
