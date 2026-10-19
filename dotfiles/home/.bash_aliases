# ~/.bash_aliases — enlazado desde David_PopOS/dotfiles/home.
# Pop!_OS carga este fichero desde ~/.bashrc por defecto.

alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'

# Nombres de Debian/Ubuntu para bat y fd.
command -v batcat >/dev/null 2>&1 && alias bat='batcat'
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'

alias gs='git status'
alias gl='git log --oneline --graph --decorate -20'

# direnv: carga .envrc por proyecto si está instalado.
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
