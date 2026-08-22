fastfetch --color "$(cat ~/.config/fastfetch/accent 2>/dev/null || echo white)"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Vide : le prompt vient de starship (voir plus bas). oh-my-zsh
# n'est gardé que pour ses plugins.
ZSH_THEME=""

plugins=(git)

source $ZSH/oh-my-zsh.sh


export PATH="$HOME/.local/bin:$PATH"

alias ll="ls -lah"

eval "$(starship init zsh)"
