#!/usr/bin/env bash

# --------------------------------- #
# EDITOR
# --------------------------------- #
if [[ "$(command -v code)" ]]; then
    EDITOR="$(command -v code)"
elif [[ "$(command -v atom)" ]]; then
    EDITOR="$(command -v atom)"
else
    EDITOR="$(command -v vim)"
fi
export EDITOR="${EDITOR}"


# --------------------------------- #
# ALIASES
# --------------------------------- #
alias l='ls -AGhlF'
alias ll='l'
SELF="$(basename "${BASH_SOURCE}")"
alias aliases="${EDITOR} ${BASH_IT}/custom/${SELF}"
alias sshconfig="${EDITOR} ${HOME}/.ssh/config"
alias dev='cd ~/code'
alias cd..='cd ..'
alias df='df -H'
alias now="$(date +%Y%m%dT%H%M)"
alias timestamp="now"
alias today=$(date +%Y%m%d)

[[ "$(command -v thefuck)" ]] && { eval "$(thefuck --alias)"; }


# --------------------------------- #
# FUNCTIONS
# --------------------------------- #
dmg() {
    if [[ -d ${1} ]] && [[ -d ${2} ]]; then
        VOL="$(basename "${1}")"
        hdiutil create -fs HFS+ -volname "${VOL}" -srcfolder "${1}" "${2}"/"${VOL}"
    else
        echo "Usage: dmg <source folder> <output folder>"
    fi
}


ff() {
    if [[ -z "${1}" ]]; then
        echo "Usage: ff <search term>"
    else
        find . -iname "${1}" 2>/dev/null
    fi
}
