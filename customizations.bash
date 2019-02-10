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
alias dev="cd ${HOME}/code"
alias cd..='cd ..'
alias df='df -H'
alias plistbuddy='/usr/libexec/PlistBuddy'
alias ping='ping --apple-time'
alias now="date +%Y%m%dT%H%M%S"
alias timestamp="now"
alias today="date +%Y%m%d"
alias macdown="open -a MacDown"
alias reload="source ${HOME}/.bash_profile"
alias ports="lsof -i -U -n -P | grep LISTEN"
alias listening='ports'
alias ag='echo "use rg instead"'

[[ "$(command -v thefuck)" ]] && { eval "$(thefuck --alias)"; }
source <(awless completion bash)

# --------------------------------- #
# FUNCTIONS
# --------------------------------- #
s3cat() {
    [[ -n "${1}" ]] || { echo "Usage: s3cat <full S3 URL>"; return 1; }
    aws s3 cp "${1}" - | cat
}

s3bat() {
    [[ -n "${1}" ]] || { echo "Usage: s3cat <full S3 URL>"; return 1; }
    which bat > /dev/null || { echo "bat not installed"; return 1; }
    aws s3 cp "${1}" - | bat
}

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

flatten() {
    [[ "$(command -v pdf2ps)" ]] || { echo "brew install ghostscript"; return 1; }
    if [[ -z "${1}" ]]; then
        echo "Usage: flatten <file>"
    else
        pdf2ps "${1}" - | ps2pdf - "${1}_flattened.pdf"
    fi
}

caps () {
    awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}' <<<"${1}"
}

lower () { 
  tr '[:upper:]' '[:lower:]' <<<"${1}"
}

upper () {
  tr '[:lower:]' '[:upper:]' <<<"${1}"
}

# same as dd but with progress meter!
ddprogress () 
{
    [ "$(which pv)" ] ||  { echo "brew install pv first"; return; }
    [ -e "${2}" ] || echo "Usage: ddprogress [SOURCE] [DESTINATION]"
    sudo pv -tpreb "${1}" | sudo dd bs=1m of="${2}"
}

# incognito mode for shell
incognito ()
{
    unset PROMPT_COMMAND;
    export HISTFILE="/dev/null";
    export HISTSIZE="0";
    history -c
}

# (macOS) generates a qr code and opens it in Preview
qr()
{
    [ "$(which qrencode)" ] || { echo "brew install qrencode first"; return; }
    qrencode "${1}" -o /tmp/qrcode.png && open /tmp/qrcode.png
}

serverhere() 
{
    myip=$(ifconfig en0 | grep "inet " | awk -F'[: ]+' '{ print $2 }');
    echo "point your browser to http://${myip}:8000";
    python -m SimpleHTTPServer 8000;
}

get_mac_address ()
{
    system_profiler SPNetworkDataType | awk -F" " '/MAC Address/ {print $3}'
}

get_serial ()
{
    system_profiler SPHardwareDataType | awk -F" " '/Serial/ {print $4}'
}
