# System utility functions — loader

_SYS_DIR="${${(%):-%x}:h}"

source "$_SYS_DIR/fs.zsh"    # Filesystem helpers : nvis  (mkd, ex → nazutils)
source "$_SYS_DIR/zsh.zsh"   # Zsh/OMZ tooling    : plugin-compile

unset _SYS_DIR
