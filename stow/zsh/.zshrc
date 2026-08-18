fastfetch

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

PROMPT='%F{white}%B %n@%m%b%f '"$PROMPT"

export PATH="$HOME/.local/bin:$PATH"

alias ll="ls -lah"
