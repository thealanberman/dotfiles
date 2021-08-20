#!/usr/bin/env bash

if [[ ! "${GOPATH}" ]]; then
  if [[ -d "${HOME}/code/go" ]]; then
    export GOPATH="${HOME}/code/go"
  else
    export GOPATH="${HOME}/go"
  fi
  export PATH="${PATH}:${GOPATH}/bin"
fi

if [[ $(command -v cargo) ]]; then
  export PATH="${HOME}/.cargo/bin:${PATH}"
fi

if [[ $(command -v mcfly) ]]; then
  eval "$(mcfly init bash)"
fi

# Enable asdf -- https://github.com/asdf-vm/asdf
[[ -f /usr/local/opt/asdf/libexec/asdf.sh ]] && source /usr/local/opt/asdf/libexec/asdf.sh

# --------------------------------- #
# DOTFILES
# --------------------------------- #
export DOTFILES="${HOME}/code/dotfiles"

# --------------------------------- #
# EDITOR
# --------------------------------- #
export EDITOR="vim"

# --------------------------------- #
# AWS PAGER
# --------------------------------- #
export AWS_PAGER=""

# --------------------------------- #
# UNAME (a.k.a OS type)
# --------------------------------- #
export UNAME=$(uname)

#--------------------------------- #
# ALIASES
# --------------------------------- #
alias l='ls -GhalF'
alias ll='l'
alias sshconfig="${EDITOR} ${HOME}/.ssh/config"
alias dev="cd ${HOME}/code"
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias df='df -H'
alias ff='fd'
alias yta="youtube-dl --ignore-errors --yes-playlist --format m4a"
alias now="date +%Y%m%dT%H%M%S"
alias reload="source ~/.bashrc" # overridden later if Darwin
alias timestamp="now"
alias today="date +%Y%m%d"
alias ports="lsof -i -U -n -P | grep LISTEN"
alias listening='ports'
alias t="tmux attach || tmux new"
alias tf="terraform"
alias box="draw"
alias dcompose="docker-compose"
alias zshell="PS1='[%n] %~%% ' zsh"
alias tips="tldr"
alias gs='git status'
alias gc='git commit'
alias gb='git branch'

# --------------------------------- #
# DARWIN ALIASES
# --------------------------------- #
if [[ "${UNAME}" == "Darwin" ]]; then
  alias reload="source ~/.bash_profile"
  alias plistbuddy='/usr/libexec/PlistBuddy'
  alias ping='ping --apple-time'
fi

# --------------------------------- #
# BASH COMPLETIONS
# --------------------------------- #
which thefuck >/dev/null && source <(thefuck --alias)
which awless >/dev/null && source <(awless completion bash)

# --------------------------------- #
# SPEED UP DOCKER BUILDS
# --------------------------------- #
export DOCKER_BUILDKIT=1

# --------------------------------- #
# TERRAFORM
# --------------------------------- #
export TF_CLI_ARGS="-no-color"

# --------------------------------- #
# PRETTIER XTRACE OUTPUT
# --------------------------------- #
export PS4='\e[2m+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }\e[0m'

# --------------------------------- #
# BETTER LESS OUTPUT
# --------------------------------- #
export LESSOPEN="| $(which highlight) %s --out-format xterm256 --quiet --force --style solarized-light"
export LESS=" -R"

# --------------------------------- #
# FUNCTIONS
# --------------------------------- #
aliases() {
  which code || "${EDITOR}" "${DOTFILES}/customizations.bash" && code "${DOTFILES}/customizations.bash"
}

s3cat() {
  [[ ${1} ]] || {
    echo "Usage: s3cat <full S3 URL>"
    return 1
  }
  aws s3 cp "${1}" - | cat
}

dmg() {
  if [[ -d ${1} ]] && [[ -d ${2} ]]; then
    VOL="$(basename "${1}")"
    hdiutil create -fs HFS+ -volname "${VOL}" -srcfolder "${1}" "${2}"/"${VOL}"
  else
    echo "Usage: dmg <source folder> <output folder>"
  fi
}

# output a handy chart of box drawing ascii characters
draw() {
  cat <<EOF

┃ ━ ┃
┏ ┳ ┓
┣ ╋ ┫
┗ ┻ ┛

EOF
}

pdf_flatten() {
  [[ "$(command -v pdf2ps)" ]] || {
    echo "brew install ghostscript"
    return 1
  }
  if [[ -z "${1}" ]]; then
    echo "Usage: flatten <file>"
  else
    pdf2ps "${1}" - | ps2pdf - "${1}_flattened.pdf"
  fi
}

capitalize() {
  awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}' <<<"${1}"
}

lowercase() {
  tr '[:upper:]' '[:lower:]' <<<"${1}"
}

uppercase() {
  tr '[:lower:]' '[:upper:]' <<<"${1}"
}

# incognito mode for shell
incognito() {
  unset PROMPT_COMMAND
  export HISTFILE="/dev/null"
  export HISTSIZE="0"
  history -c
}

# (macOS) generates a qr code and opens it in Preview
qr() {
  [[ "$(command -v qrencode)" ]] || {
    echo "brew install qrencode first"
    return
  }
  qrencode "${1}" -o /tmp/qrcode.png && open /tmp/qrcode.png
}

serverhere() {
  myip=$(ifconfig en0 | grep "inet " | awk -F'[: ]+' '{ print $2 }')
  echo "point your browser to http://${myip}:8000"
  python3 -m http.server 8000
}

get_mac_address() {
  system_profiler SPNetworkDataType | awk -F" " '/MAC Address/ {print $3}'
}

get_serial() {
  system_profiler SPHardwareDataType | awk -F" " '/Serial/ {print $4}'
}

json2yaml() {
  ruby -ryaml -rjson -e 'puts YAML.dump(JSON.parse(STDIN.read))' <"${1}" >"${1}.yaml"
  echo "Created ${1}.yaml"
}

yaml2json() {
  ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' <"${1}" >"${1}.json"
  echo "Created ${1}.json"
}

kh() {
  [[ ${1} ]] || {
    echo "USAGE: kh <host to remove from known_hosts>"
    return 1
  }
  ssh-keygen -R "${1}"
}

retry() {
  [[ ${1} ]] || {
    echo "USAGE: retry <number of tries> <command>"
    return 1
  }
  local retries="${1}"
  shift
  local count=0
  until "${@}"; do
    exit=$?
    wait=$((2 ** count))
    count=$((count + 1))
    if [[ ${count} < ${retries} ]]; then
      echo "Retry ${count}/${retries} exited ${exit}, retrying in ${wait} seconds..."
      sleep ${wait}
    else
      echo "Retry ${count}/${retries} exited ${exit}, no more retries left."
      return ${exit}
    fi
  done
  return 0
}

audio_trim() {
  [[ $2 ]] || {
    echo "Usage: audio_trim <file> <seconds to keep>"
    return 1
  }
  ffmpeg -ss 0 -t "${2}" -i "${1}" -vn -c copy "${1%.*}_trimmed.${1##*.}"
}

alias audio_substr="audio_selection"
audio_selection() {
  [[ $2 ]] || {
    echo "Usage: audio_selection <file> <HH:MM:SS> <HH:MM:SS>"
    return 1
  }
  ffmpeg -i "${1}" -ss "${2}" -to "${3}" -c copy "${1%.*}_selection.${1##*.}"
}

audio_join() {
  [[ ${3} ]] || {
    echo "Usage: audio_join <file1> <file2> <output>"
    return 1
  }
  local pwd=$(pwd)
  echo "file \"${pwd}/${1}\"" >/tmp/list.txt
  echo "file \"${pwd}/${2}\"" >>/tmp/list.txt
  ffmpeg -f concat -safe 0 -i /tmp/list.txt -c copy "${pwd}/${3}"
  rm /tmp/list.txt
}

hashafter() {
  { [[ $1 ]] && [[ $2 ]]; } || {
    echo "Check SHA sum of all files after line N."
    echo "Usage: hashafter <filename> <line number>"
    return 1
  }
  shasum <<<$(sed -n "${2},\$p" "${1}") | cut -d' ' -f1
}

ramdisk() {
  [[ $1 ]] || {
    echo "Usage: ramdisk <megabytes>"
    return 1
  }
  ramdisk_size=$((${1} * 2048))
  diskutil erasevolume HFS+ 'RAMDisk' "$(hdiutil attach -nobrowse -nomount ram://${ramdisk_size})"
}

splay() {
  [[ $1 ]] || {
    echo "Usage: splay <seconds> <command>"
    return 1
  }
  local seconds=$((RANDOM % ${1}))
  sleep ${seconds}
  shift
  eval "${@}"
}

loop() {
  while true; do
    $@
  done
}

a2v() {
  [[ $1 ]] || { 
    echo "Audio 2 Video"
    echo "USAGE: a2v <image file> <audio file>"
    return 1
    }
  outfile=$(basename "${2}" | tr -d " ")
  ffmpeg -r 1 -loop 1 \
  -i "${1}" \
  -i "${2}" \
  -acodec copy -r 1 -shortest \
  "${outfile%.*}.mp4"
}
