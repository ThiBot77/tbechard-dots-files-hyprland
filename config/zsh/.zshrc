# L'accent suit le theme quickshell : applycolor.sh ecrit la couleur primary
# dans le state dir a chaque changement de fond d'ecran ou de schema. Repli sur
# l'accent statique du depot, puis sur blanc.
ff_accent="$(cat ~/.local/state/quickshell/user/generated/terminal/accent 2>/dev/null \
    || cat ~/.config/fastfetch/accent 2>/dev/null || echo white)"
fastfetch --color "$ff_accent"
unset ff_accent

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
