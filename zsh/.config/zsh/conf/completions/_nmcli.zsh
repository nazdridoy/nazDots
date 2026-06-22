# Native zsh completion for nmcli
# The system only ships a bash completion for nmcli. The bash script uses
# bash-only constructs (${!ARRAY[@]}, compopt, shopt) that break in zsh even
# with bashcompinit. Instead, we write a native zsh completion that calls
# `nmcli --complete-args` directly (the same backend the bash script uses).
_nmcli() {
  local -a args
  # $words is auto-populated by zsh's completion system; words[1] is 'nmcli'
  # Pass only the arguments (words[2..$CURRENT]) to --complete-args
  args=("${words[@]:1}")   # drop 'nmcli' itself

  local output
  output="$(command nmcli --complete-args "${args[@]}" 2>/dev/null)"
  local ret=$?

  # Exit code 65 means "complete a filename"
  if (( ret == 65 )); then
    _files
    return
  fi

  local -a completions
  completions=("${(@f)output}")   # split output on newlines into array
  compadd -a completions
}

compdef _nmcli nmcli
