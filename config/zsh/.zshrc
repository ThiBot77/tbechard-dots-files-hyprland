# Accent ecrit par applycolor.sh, avec repli sur le depot puis sur blanc.
ff_accent="$(cat ~/.local/state/quickshell/user/generated/terminal/accent 2>/dev/null \
    || cat ~/.config/fastfetch/accent 2>/dev/null || echo white)"
fastfetch --color "$ff_accent"
unset ff_accent

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Vide : le prompt vient de starship.
ZSH_THEME=""

plugins=(git)

source $ZSH/oh-my-zsh.sh


export PATH="$HOME/.local/bin:$PATH"

alias ll="ls -lah"

# Se source apres oh-my-zsh, qui redefinit sinon les widgets d'edition.
autosuggest="/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
if [[ -r "$autosuggest" ]]; then
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    source "$autosuggest"
fi
unset autosuggest

# Fleches haut/bas : filtre l'historique sur le debut de ligne deja tape.
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

eval "$(starship init zsh)"
