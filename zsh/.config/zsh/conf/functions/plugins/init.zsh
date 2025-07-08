# Initialize external plugins and tools

# tere file explorer
tere() {
    local result=$(command tere "$@")
    [ -n "$result" ] && cd -- "$result"
}

# Initialize zoxide
eval "$(zoxide init zsh --hook pwd)"

#Navi Cheatsheet (load after oh-my-zsh.sh)
eval "$(navi widget zsh)"

# shell autocompletion for uv and uvx
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"

# Initialize atuin
eval "$(atuin init zsh  --disable-up-arrow)"