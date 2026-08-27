# Filesystem utility functions

# Open a script by name in nvim
nvis() {
  nvim $(which $1)
}

# Create directory/directories and cd into the result
mkd() {
    local dirs=("$@")
    command mkdir -p "${dirs[@]}" || return 1
    if (( ${#dirs[@]} > 1 )); then
        local selected
        selected=$(printf '%s\n' "${dirs[@]}" | fzf --prompt="Select directory: " --height=~50%)
        [[ -n "$selected" ]] && cd "$selected" && pwd
    else
        cd "${dirs[1]}" && pwd
    fi
}
