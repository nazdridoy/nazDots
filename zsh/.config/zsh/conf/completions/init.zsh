# Load all custom completion modules

# Define the completions directory
COMPLETIONS_DIR="${${(%):-%x}:h}"

# nmcli native zsh completion
source "$COMPLETIONS_DIR/_nmcli.zsh"
