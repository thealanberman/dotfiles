autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
export PATH="/opt/homebrew/bin:$PATH"
export HISTCONTROL=ignoreboth:erasedups
source ${HOME}/code/dotfiles/customizations.zsh
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search   # Up
bindkey "^[[B" down-line-or-beginning-search # Down

############
# STARSHIP #
############
export STARSHIP_CONFIG=${HOME}/code/dotfiles/starship.toml
source <(/opt/homebrew/bin/starship init zsh --print-full-init)
