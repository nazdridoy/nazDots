# Load all function modules

# Define the functions directory
FUNCTIONS_DIR="${${(%):-%x}:h}"

# Load plugin initializations
source "$FUNCTIONS_DIR/pluginInits/init.zsh"

# Load system utilities
source "$FUNCTIONS_DIR/system/init.zsh"

# Load web search functions
source "$FUNCTIONS_DIR/search/web.zsh"

# Load AI-related functions
source "$FUNCTIONS_DIR/ai/ai-env.zsh"