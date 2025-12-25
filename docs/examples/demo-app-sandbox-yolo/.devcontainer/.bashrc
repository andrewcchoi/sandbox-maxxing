# Custom bash configuration for Custom Configuration development

# Enhanced prompt with git branch
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
export PS1="\[\033[01;36m\][YOLO]\[\033[00m\] \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]\$(parse_git_branch)\[\033[00m\]\$ "

# Aliases for development
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias pytest='python -m pytest'
alias black='python -m black'
alias isort='python -m isort'
alias flake8='python -m flake8'
alias mypy='python -m mypy'

# Docker aliases
alias dc='docker-compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlogs='docker-compose logs -f'

# Git aliases
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Python environment
export PYTHONPATH="/workspace:$PYTHONPATH"
export PIP_USER=1

# Node environment
export PATH="$HOME/.npm-global/bin:$PATH"

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# History configuration
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Auto-completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# Welcome message
echo "🚀 Custom Configuration Development Environment"
echo "Python: $(python --version)"
echo "Node.js: $(node --version)"
echo "Git: $(git --version)"
