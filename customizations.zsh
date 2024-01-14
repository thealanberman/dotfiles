#!/usr/bin/env zsh

# dedupe history, ignore commands with leading space
export HISTCONTROL=ignoreboth:erasedups

export PATH="/opt/homebrew/sbin:/usr/local/sbin:${PATH}"

# turn on quick 'cd' to common folders
setopt auto_cd
cdpath=("${HOME}" "${HOME}/code" "${HOME}/Sync")

# pasted URLs are automatically quoted, without needing to disable globbing
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

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
  HISTFILE=${HOME}/.zsh_history
  eval "$(mcfly init zsh)"
fi

if [[ $(command -v pyenv) ]]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
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
# PAGER
# --------------------------------- #
export PAGER="less -X"

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
alias yta="yt-dlp -x --audio-format m4a"
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
alias ts='/Applications/Tailscale.app/Contents/MacOS/Tailscale'
alias pm='/opt/homebrew/bin/podman'
  
# --------------------------------- #
# DARWIN ALIASES
# --------------------------------- #
if [[ "${UNAME}" == "Darwin" ]]; then
  alias reload="source ~/.zshrc"
  alias plistbuddy='/usr/libexec/PlistBuddy'
  alias ping='ping --apple-time'
fi

# --------------------------------- #
# COMPLETIONS
# --------------------------------- #
which thefuck >/dev/null && source <(thefuck --alias)

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
  which code || "${EDITOR}" "${DOTFILES}/customizations.zsh" && code "${DOTFILES}/customizations.zsh"
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
  ffmpeg -i "concat:${1}|${2}" -c copy "${3}"
}

audio_extract() {
  [[ ${1} ]] || {
    echo "Usage: audio_extract <video file>"
    return 1
  }

  declare -A audioFormat
  audioFormat[aac]="m4a"
  audioFormat[mp3]="mp3"
  audioFormat[eac]="ac3"

  fmt=$(ffprobe "${1}" 2>&1 | grep -m1 "Audio" | sed -En 's/.*Audio: (...).*/\1/p')
  ffmpeg -i "${1}" -vn -acodec copy "${1%.*}.${audioFormat[${fmt}]}"
  echo "Output: ${1%.*}.${audioFormat[${fmt}]}"
}

audio_chunk() {
  if [[ -z ${1} ]] || [[ -z ${2} ]]; then
    echo "Usage: audio_chunk <audio file> <number of chunks>"
    return 1
  fi

  seconds=$(ffprobe -i "${1}" -show_entries format=duration -v quiet -of csv="p=0")
  roundedup="$(printf "%.0f\n" "${seconds}")"
  segment_length=$(((roundedup + 1) / ${2}))
  ffmpeg -i "${1}" -f segment -segment_time "${segment_length}" "output_%03d.${1##*.}"
}

subtitle_extract() {
  [[ ${1} ]] || {
    echo "Usage: subtitle_extract <video file>"
    return 1
  }
  info=$(ffprobe -v error -select_streams s -show_entries stream=index,codec_name,stream_tags=language,format_tags=format -of csv=p=0 "${1}" | grep -Ei 'subrip|ssa|ass')
  fmt=$(echo "${info}" | awk -F',' '{print $2}')
  stream=$(echo "${info}" | awk -F',' '{print $1}')

  case "${fmt}" in
  subrip)
    ffmpeg -i "${1}" -map 0:${stream} -c:s srt "${1%.*}.srt"
    echo "Output: ${1%.*}.srt"
    ;;
  ssa|ass)
    ffmpeg -i "${1}" -map 0:${stream} -c:s srt "${1%.*}.srt"
    echo "Output: ${1%.*}.ass"
    ;;
  *)
    echo "not sure what extension to use for ${fmt}"
    ;;
  esac
}

subtitle_merge() {
  [[ ${1} ]] || {
    echo "Usage: subtitle_merge <video file> <subtitle file>"
    return 1
  }
  if [[ "${1##*.}" == "mp4" ]]; then
    ffmpeg -i "${1}" -i "${2}" -c copy -c:s mov_text "${1%.*}_merged.${1##*.}"
  fi
  if [[ "${1##*.}" == "mkv" ]]; then
    mkvmerge "${1}" -o "${1%.*}_merged.${1##*.}" --language 0:eng "${2}"
  fi
  echo "Output: ${1%.*}_merged.${1##*.}"
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
  diskutil erasevolume HFS+ 'RAMDisk' $(hdiutil attach -nobrowse -nomount ram://${ramdisk_size})
}

splay() {
  [[ $1 ]] || {
    echo "delay a command by a random 1 to N seconds"
    echo "Usage: splay N <command>"
    return 1
  }
  local seconds=$((RANDOM % $1))
  sleep ${seconds}
  shift
  $@
}

# loop any command. don't use this with ping.
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

# because dig on macOS behaves differently
alias dnsquery='dscacheutil -q host -a name'
dig() {
  [[ $UNAME == "Darwin" ]] && echo "$(tput bold)macOS detected. Try 'dnsquery' instead?$(tput sgr0)"
  /usr/bin/dig $@
}

fix() {
  echo -e "AUDIO:\n\tsudo launchctl kickstart -kp system/com.apple.audio.coreaudiod"
  echo
  echo -e "BLUETOOTH:\n\tsudo launchctl kickstart -kp system/com.apple.audio.bluetoothd"
  echo
  echo -e "ICONS:\n\tsudo pkill com.apple.quicklook.ThumbnailsAgent; sudo killall Finder"
}

k() {
  [[ -z $1 ]] && {
    echo "keychain entry lookup + copy to clipboard"
    echo "USAGE: k <unique NAME of keychain entry>"
    return 1
  }
  security find-generic-password -w -l "${1}" | pbcopy && echo "password copied to clipboard"
}

# mst3k upscale project download params
ytm() {
  yt-dlp -N 4 -f 299+140 "${1}"
}

venv() {
  if [[ ! -d venv ]]; then
    python -m venv venv
  fi
  source venv/bin/activate
  which python
}