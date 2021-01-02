if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [[ -f /etc/bashrc ]]; then
        source /etc/bashrc
    fi

    if [[ -f /etc/bash.bashrc ]]; then
        source /etc/bash.bashrc
    fi

    if [[ -f "$HOME/.bashrc" ]]; then
        source "$HOME/.bashrc"
    fi
fi


