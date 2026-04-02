export EDITOR=nvim
export TERM="xterm-256color"
export HISTCONTROL=ignoreboth:erasedups

export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/local/bin:$PATH"

if [[ "$(uname -s)" == "Darwin" ]]; then
    export COLIMA_HOME=$HOME/.colima
    export DOCKER_HOST="unix://$COLIMA_HOME/default/docker.sock"
fi
export PATH="$ILYASYOY_DOTFILES_DIR/bin:$PATH"
