# Zsh / Oh-My-Zsh tooling functions

# Compile all zsh plugin/config files to byte code for faster loading
plugin-compile() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: plugin-compile [-v]"
    echo ""
    echo "Compile zsh plugins and configuration files to byte code for faster loading"
    echo ""
    echo "Options:"
    echo "  -v    Verbose mode - show detailed compilation progress"
    echo "  -h    Show this help message"
    echo ""
    echo "Directories processed:"
    echo "  - \$ZSH_CUSTOM     (Custom plugins and themes)"
    echo "  - \$ZSH/plugins    (Oh-My-Zsh plugins)"
    echo "  - \$ZSH/lib        (Oh-My-Zsh library files)"
    echo "  - \$ZDOTDIR/conf   (User configuration files)"
    echo ""
    echo "Example:"
    echo "  plugin-compile     # Quiet compilation"
    echo "  plugin-compile -v  # Show compilation details"
    return 0
  fi

  local dirs=(
    "$ZSH_CUSTOM"
    "$ZSH/plugins"
    "$ZSH/lib"
    "$ZDOTDIR/conf"
  )

  local verbose=false
  if [[ "$1" == "-v" ]]; then
    verbose=true
    shift
  fi

  autoload -U zrecompile

  for dir in $dirs; do
    if [[ ! -d "$dir" ]]; then
      echo "Warning: Directory $dir does not exist"
      continue
    fi

    echo "Compiling files in $dir..."
    for file in "$dir"/**/*.zsh{,-theme}(N); do
      if $verbose; then
        echo "Compiling: $file"
        zrecompile -p "$file"
      else
        zrecompile -pq "$file"
      fi
    done
  done

  echo "Plugin compilation complete!"
}
