# Load all function modules

# Define the functions directory
FUNCTIONS_DIR="${${(%):-%x}:h}"

# Load plugin initializations
source "$FUNCTIONS_DIR/plugins/init.zsh"

# Load system utilities
source "$FUNCTIONS_DIR/system/utils.zsh"

# Load web search functions
source "$FUNCTIONS_DIR/search/web.zsh"

# Load AI-related functions
source "$FUNCTIONS_DIR/ai/tgpt.zsh"