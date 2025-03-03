########################################################
#####            Functions for Extra Plugins       #####
########################################################

# tere file expoler
tere() {
    local result=$(command tere "$@")
    [ -n "$result" ] && cd -- "$result"
}
#Initialize zoxide
eval "$(zoxide init zsh --hook pwd)"

#Navi Cheatsheet (load after oh-my-zsh.sh)
eval "$(navi widget zsh)"

# AM autocompletion
#autoload bashcompinit
#bashcompinit
#source "/home/nazmul/.config/zsh/.bash_completion"

# shell autocompletion for uv and uvx
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"



########################################################
#####            Custom Function Define            #####
########################################################

# Function for Compiling Plugins to byte code 
function plugin-compile {
  # Handle help flags
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

  # Add error handling
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
  
  # Check if directories exist
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



# Open scripts by its name
nvis () {
  nvim $(which $1)
}

########################################################
#####               Web Search Tools                #####
########################################################

# Web search functions 
# Usage: ddg query, ggl query, srx query, etc.

# DuckDuckGo search
ddg() {
  w3m "duckduckgo.com/lite?q=$*"
}

# Google search
ggl() {
  w3m "google.com/search?&q=$*"
}

# Searx.be search
srx() {
  w3m "https://searx.be/search?q=$*"
}

# command-not-found.com search
cmd() {
  w3m "https://command-not-found.com/$*"
}

# cheat.sh searches
# w3m browser version (for reading)
wcht() {
  w3m "cht.sh/$*"
}

# curl version (for copying/piping)
cht() {
  curl "cheat.sh/$1"
}

# Create a directory and change into it at the same time
mkd() {
  # Add error handling and feedback
  if [[ $# -eq 0 ]]; then
    echo "Usage: mkd <directory_name> [directory_name2 ...]"
    return 1
  fi
  
  mkdir -p "$@"
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create directory"
    return 1
  fi
  
  if [[ "$#" -gt 1 ]]; then
    echo "Multiple directories created. Select one to enter:"
    selected_dir=$(echo "$@" | tr ' ' '\n' | fzf)
    [[ -n "$selected_dir" ]] && cd "$selected_dir" && pwd
  else
    cd "$1" && pwd
  fi
}




########################################################
#####               AI Tools & tgpt                #####
########################################################

## tgpt with gpt4free
tptg() {
    local prompt=""
    local provider=""
    local model=""
    local base_url="http://localhost:1337"
    local skip_interactive=false
    local skip_screen_clear=false
    local exporting_enabled=${G4F_EXPORT_ENABLED:-0}  # Check if export is enabled
    local post_prompt_args=()  # Array to hold arguments that come after the prompt
    local prompt_found=false   # Flag to track if we've found the prompt
    
    # Define color codes
    local BLUE='\033[0;34m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local CYAN='\033[0;36m'
    local PURPLE='\033[0;35m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m' # No Color
    
    # Check for help flag first (special case)
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo -e "${BOLD}Usage:${NC} tptg [options] <query> [tgpt_options]"
        echo ""
        echo -e "${BOLD}Options:${NC}"
        echo -e "  -pr <provider_id> : Specify provider ID directly"
        echo -e "  -ml <model_id>    : Specify model ID directly"
        echo -e "  --help, -h        : Show this help message"
        echo ""
        echo -e "${BOLD}Examples:${NC}"
        echo -e "  tptg \"What is quantum computing?\""
        echo -e "  tptg -pr DDG -ml o3-mini \"What is quantum computing?\""
        echo -e "  tptg \"cute cat\" --img      # Pass --img to tgpt"
        echo ""
        echo -e "${YELLOW}Note:${NC}"
        echo -e "  1. Any options after the prompt are passed directly to tgpt"
        echo -e "  2. Requires a local gpt4free instance running at http://localhost:1337"
        return 0
    fi
    
    # Parse arguments - looking for pre-prompt options and the prompt itself
    while [[ $# -gt 0 ]]; do
        # If we've already found the prompt, collect remaining args for tgpt
        if $prompt_found; then
            post_prompt_args+=("$1")
            shift
            continue
        fi
        
        case "${1:-}" in
            "-pr")
                shift
                if [[ -z "$1" || "$1" == -* ]]; then
                    echo -e "${RED}Error:${NC} -pr requires a provider ID argument"
                    return 1
                fi
                provider="$1"
                shift
                ;;
            "-ml")
                shift
                if [[ -z "$1" || "$1" == -* ]]; then
                    echo -e "${RED}Error:${NC} -ml requires a model ID argument"
                    return 1
                fi
                model="$1"
                shift
                ;;
            *)
                # This argument is our prompt
                prompt="$1"
                prompt_found=true
                shift
                ;;
        esac
    done
    
    # Check if prompt is provided
    if [[ -z "$prompt" ]]; then
        echo -e "${RED}Error:${NC} No prompt provided"
        echo -e "Usage: tptg [options] <query> [tgpt_options]"
        return 1
    fi
    
    # Check if both provider and model are provided to skip interactive selection
    if [[ -n "$provider" && -n "$model" ]]; then
        skip_interactive=true
        skip_screen_clear=true  # Skip screen clearing when both are directly specified
    elif [[ -n "$provider" || -n "$model" ]]; then
        # Error if only one of -pr or -ml is provided
        echo -e "${RED}Error:${NC} Both -pr and -ml must be specified together"
        echo -e "Example: tptg -pr DDG -ml o3-mini \"What is quantum computing?\""
        return 1
    fi
    
    # Check if gpt4free server is running
    if ! curl -s "$base_url/v1/models" > /dev/null; then
        echo -e "${RED}Error:${NC} Cannot connect to gpt4free server at $base_url"
        echo -e "Make sure the server is running and accessible"
        return 1
    fi
    
    # Function to clear screen and show header - Now respects skip_screen_clear flag
    clear_and_show_header() {
        # Only clear if not skipping
        if ! $skip_screen_clear; then
            # Use both clear command and ANSI escape sequence for more thorough clearing
            clear
            printf "\033c"  # ANSI escape sequence to reset terminal
            
            # Use simpler box drawing with fixed width
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
            echo -e "${BOLD}${BLUE}|       ${CYAN}GPT4Free Interface${BLUE}             |${NC}"
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
            
            # Simplify query display to avoid parameter expansion issues
            local display_prompt="$prompt"
            if [[ ${#display_prompt} -gt 25 ]]; then
                display_prompt="${display_prompt:0:25}..."
            fi
            echo -e "${BOLD}${BLUE}| ${YELLOW}Query:${NC} $display_prompt${BLUE} |${NC}"
            
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
            echo ""
        fi
    }
    
    # Skip interactive selection if provider and model are specified
    if ! $skip_interactive; then
        # Provider selection loop
        while true; do
            clear_and_show_header
            
            # Get available providers
            echo -e "${CYAN}Fetching available providers...${NC}"
            local providers=$(curl -s -X 'GET' "$base_url/v1/models" \
                -H 'accept: application/json' | jq -r '.data[] | select(.provider == true) | .id')
            
            if [[ -z "$providers" ]]; then
                echo -e "${RED}Error:${NC} No providers found"
                return 1
            fi
            
            # Create a numbered menu for provider selection
            echo -e "${BOLD}${GREEN}Available providers:${NC}"
            echo ""  # Add spacing before provider list
            local i=1
            local provider_array=()
            while read -r p; do
                # Use different colors for alternating rows
                if (( i % 2 == 0 )); then
                    echo -e "  ${CYAN}$i)${NC} $p"
                else
                    echo -e "  ${PURPLE}$i)${NC} $p"
                fi
                provider_array+=("$p")
                ((i++))
            done <<< "$providers"
            echo ""  # Add spacing after provider list
            
            # Get user selection
            echo -e -n "${YELLOW}Select provider (1-$((i-1))): ${NC}"
            read selection
            
            # Validate selection
            if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $((i-1)) ]; then
                echo -e "${RED}Error:${NC} Invalid selection"
                sleep 1  # Brief pause to show error
                continue
            fi
            
            # Arrays in zsh are 1-indexed, adjust the index
            provider="${provider_array[$selection]}"
            
            # Clear screen before showing models
            clear_and_show_header
            echo -e "${BOLD}Selected provider:${NC} ${GREEN}'$provider'${NC}"
            
            # Get available models for the selected provider
            echo -e "${CYAN}Fetching models for provider '$provider'...${NC}"
            local models=$(curl -s -X 'GET' "$base_url/api/$provider/models" \
                -H 'accept: application/json' | jq -r '.data[] | .id')
            
            if [[ -z "$models" ]]; then
                echo -e "${RED}Error:${NC} No models found for provider '$provider'"
                echo -e "Please select a different provider."
                sleep 2  # Pause to show error message
                continue
            fi
            
            # Create a numbered menu for model selection with back option
            echo -e "${BOLD}${GREEN}Available models for $provider:${NC}"
            echo ""  # Add spacing before the back option
            echo -e "  ${BOLD}${YELLOW}0)${NC} ${BOLD}${YELLOW}← Go back to provider selection${NC}"
            echo ""  # Add spacing to separate back option from models
            local i=1
            local model_array=()
            while read -r m; do
                # Use different colors for alternating rows
                if (( i % 2 == 0 )); then
                    echo -e "  ${CYAN}$i)${NC} $m"
                else
                    echo -e "  ${PURPLE}$i)${NC} $m"
                fi
                model_array+=("$m")
                ((i++))
            done <<< "$models"
            
            # Get user selection
            echo -e -n "${YELLOW}Select model (0 to go back, 1-$((i-1)) to select): ${NC}"
            read selection
            
            # Check if user wants to go back
            if [[ "$selection" == "0" ]]; then
                echo -e "${BLUE}Going back to provider selection...${NC}"
                sleep 1.5  # Longer pause before clearing
                # Force a more thorough clearing
                clear
                printf "\033c"
                continue
            fi
            
            # Validate selection
            if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $((i-1)) ]; then
                echo -e "${RED}Error:${NC} Invalid selection"
                sleep 1  # Brief pause to show error
                continue
            fi
            
            # Arrays in zsh are 1-indexed, adjust the index
            model="${model_array[$selection]}"
            
            # Clear screen before final output
            clear_and_show_header
            echo -e "${BOLD}Selected provider:${NC} ${GREEN}'$provider'${NC}"
            echo -e "${BOLD}Selected model:${NC} ${GREEN}'$model'${NC}"
            break
        done
    else
        # Using directly specified provider and model
        clear_and_show_header
        echo -e "${BOLD}Using specified provider:${NC} ${GREEN}'$provider'${NC}"
        echo -e "${BOLD}Using specified model:${NC} ${GREEN}'$model'${NC}"
    fi
    
    # At the end of the selection process, add conditional exports:
    if [[ -n "$provider" && -n "$model" ]]; then
        # Only export if called from gitcommsg (flag set)
        if [[ "$exporting_enabled" == "1" ]]; then
            export G4F_SELECTED_PROVIDER="$provider"
            export G4F_SELECTED_MODEL="$model"
        fi
    fi
    
    # Run tgpt with the selected provider and model, including any post-prompt args
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    echo -e "${BOLD}${BLUE}| ${CYAN}Using provider:${NC} ${GREEN}$provider${NC}"
    echo -e "${BOLD}${BLUE}| ${CYAN}Using model:${NC} ${GREEN}$model${NC}"
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    echo -e "${YELLOW}Sending request...${NC}"
    
    # Pass any post-prompt args to tgpt
    tgpt --provider openai \
         "${post_prompt_args[@]}" \
         --url "$base_url/api/$provider/chat/completions" \
         --model "$model" \
         "$prompt"
}

## tgpt with phind
tptp() {
    local use_tor=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "${1:-}" in
            "--tor")
                use_tor=true
                shift
                ;;
            "--help"|"-h")
                echo "Usage: tptp [--tor] <query>"
                echo ""
                echo "Options:"
                echo "  --tor      : Route traffic through Tor network"
                return 0
                ;;
            *)
                break
                ;;
        esac
    done

    if $use_tor; then
        if ! command -v torify >/dev/null 2>&1; then
            echo "Error: torify not found. Please install tor package."
            return 1
        fi
        torify tgpt --provider phind "$@"
    else
        tgpt --provider phind "$@"
    fi
}

## tgpt with duckduckgo provider and multiple models
tptd() {
    local model="o3-mini"  # Set default model first
    local use_tor=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "${1:-}" in
            "--tor")
                use_tor=true
                shift
                ;;
            "gpt"|"1")
                model="gpt-4o-mini"
                shift
                ;;
            "llama"|"2")
                model="meta-llama/Llama-3.3-70B-Instruct-Turbo"
                shift
                ;;
            "claude"|"3")
                model="claude-3-haiku-20240307"
                shift
                ;;
            "o3"|"4")
                model="o3-mini"
                shift
                ;;
            "mistral"|"5")
                model="mistralai/Mistral-Small-24B-Instruct-2501"
                shift
                ;;
            "--help"|"-h")
                echo "Usage: tptd [--tor] [model] <query>"
                echo "Available models:"
                echo "  gpt, 1     : gpt-4o-mini"
                echo "  llama, 2   : Llama-3.3-70B-Instruct-Turbo"
                echo "  claude, 3  : claude-3-haiku-20240307"
                echo "  o3, 4      : o3-mini"
                echo "  mistral, 5 : Mistral-Small-24B-Instruct-2501"
                echo "Default: o3-mini"
                echo ""
                echo "Options:"
                echo "  --tor      : Route traffic through Tor network"
                return 0
                ;;
            *)
                break
                ;;
        esac
    done

    # Check if torify is available when --tor is used
    if $use_tor; then
        if ! command -v torify >/dev/null 2>&1; then
            echo "Error: torify not found. Please install tor package."
            return 1
        fi
        torify tgpt --provider duckduckgo --model "$model" "$@"
    else
        tgpt --provider duckduckgo --model "$model" "$@"
    fi
}

## tgpt with CloudFlare AI API
tptc() {
    local model="@cf/meta/llama-3.1-8b-instruct"  # Set default model first
    local use_tor=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "${1:-}" in
            "--tor")
                use_tor=true
                shift
                ;;
            "llama"|"1")
                model="@cf/meta/llama-3.1-8b-instruct"
                shift
                ;;
            "deepseek"|"2")
                model="@cf/deepseek-ai/deepseek-r1-distill-qwen-32b"
                shift
                ;;
            "llama70b"|"3")
                model="@cf/meta/llama-3.3-70b-instruct-fp8-fast"
                shift
                ;;
            "--help"|"-h")
                echo "Usage: tptc [--tor] [model] <query>"
                echo "Available models:"
                echo "  llama, 1     : @cf/meta/llama-3.1-8b-instruct"
                echo "  deepseek, 2  : @cf/deepseek-ai/deepseek-r1-distill-qwen-32b"
                echo "  llama70b, 3  : @cf/meta/llama-3.3-70b-instruct-fp8-fast"
                echo "Default: @cf/meta/llama-3.1-8b-instruct"
                echo ""
                echo "Options:"
                echo "  --tor      : Route traffic through Tor network"
                echo ""
                echo "Note: Requires CloudFlare credentials. Run setCFenv first."
                return 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Check if CloudFlare environment variables are set (only when making a query)
    if [[ -z "$CF_WAI_API_Key" || -z "$CF_WAI_ACC" ]]; then
        echo "Error: CloudFlare credentials not set. Run setCFenv first."
        return 1
    fi
    
    if $use_tor; then
        if ! command -v torify >/dev/null 2>&1; then
            echo "Error: torify not found. Please install tor package."
            return 1
        fi
        torify tgpt --provider openai \
             --url "https://api.cloudflare.com/client/v4/accounts/${CF_WAI_ACC}/ai/v1/chat/completions" \
             --model "$model" \
             --key "${CF_WAI_API_Key}" \
             "$@"
    else
        tgpt --provider openai \
             --url "https://api.cloudflare.com/client/v4/accounts/${CF_WAI_ACC}/ai/v1/chat/completions" \
             --model "$model" \
             --key "${CF_WAI_API_Key}" \
             "$@"
    fi
}

## tgpt with nazOllama_colab_API
tptn() {
    local model=""
    local use_tor=false
    local api_url
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "${1:-}" in
            "--tor")
                use_tor=true
                shift
                ;;
            "-ml")
                shift
                if [[ -z "$1" ]]; then
                    echo "Error: -ml requires a model name"
                    return 1
                fi
                model="$1"
                shift
                ;;
            "--help"|"-h")
                echo "Usage: tptn --tor -ml <modelname> <query>"
                echo "Options:"
                echo "  --tor    : Route traffic through Tor network"
                echo "  -ml      : REQUIRED - Specify model name (e.g. deepseek-r1:14b)"
                echo "Example:"
                echo "  tptn -ml deepseek-r1:14b 'what is quantum computing?'"
                echo "  tptn --tor -ml llama3.2:latest 'explain dark matter'"
                return 0
                ;;
            *)
                break
                ;;
        esac
    done

    # Validate model is provided
    if [[ -z "$model" ]]; then
        echo "Error: Model name is required. Use -ml to specify a model."
        echo "Example: tptn -ml deepseek-r1:14b 'your question'"
        return 1
    fi

    # Get dynamic URL
    if ! api_url=$(curl -sL https://nazkvhub.nazdridoy.workers.dev/v1/query/ollama-tunnel | jq -r '.url'); then
        echo "Error: Failed to retrieve API URL"
        return 1
    fi

    if $use_tor; then
        if ! command -v torify >/dev/null 2>&1; then
            echo "Error: torify not found. Please install tor package."
            return 1
        fi
        torify tgpt --provider openai \
            --url "$api_url/v1/chat/completions" \
            --model "$model" \
            "$@"
    else
        tgpt --provider openai \
            --url "$api_url/v1/chat/completions" \
            --model "$model" \
            "$@"
    fi
}

# Generic template function for tgpt commands
_xtgpt() {
    local cmd="$1"
    local template=""
    local use_tor=false
    local model=""
    local provider=""
    local provider_arg=""
    local model_arg=""
    
    shift  # Remove the command name from arguments

    # Handle help first
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: xtptp/xtptd/xtptc/xtptn/xtptg <template> [--tor] [model]"
        echo ""
        echo "Replace placeholders in the template with input and execute the command."
        echo ""
        echo "Arguments:"
        echo "  <template>    A text template with placeholders (e.g. 'hello {}, how are you?')"
        echo "  --tor        Route traffic through Tor network"
        echo "  [model]       For xtptd: model number (1-5) or name (gpt/llama/claude/o3/mistral)"
        echo "                For xtptc: model number (1-3) or name (llama/deepseek/llama70b)"
        echo "                For xtptn: Use -ml <modelname> to specify model"
        echo "                For xtptg: Use -pr <provider> -ml <model> to specify provider and model"
        echo ""
        echo "Example:"
        echo "  echo \"Vscode\" | xtptd \"what is {}, can it play music?\" --tor claude"
        echo "  echo \"Python\" | xtptc \"explain {} in simple terms\" --tor llama70b"
        echo "  echo \"Docker\" | xtptn --tor -ml deepseek-r1:14b 'how to optimize {} containers?'"
        echo "  echo \"AI\" | xtptg \"explain {}\" -pr DDG -ml o3-mini"
        echo "  echo \"AI\" | xtptg \"explain {}\" -ml deepseek-r1:14b"
        echo ""
        return 0
    fi
    
    # Parse all arguments first
    while [[ $# -gt 0 ]]; do
        case "$1" in
            "--tor")
                use_tor=true
                shift
                ;;
            "-pr")
                shift
                if [[ -z "$1" || "$1" == -* ]]; then
                    echo "Error: -pr requires a provider ID argument"
                    return 1
                fi
                provider="$1"
                provider_arg="-pr"
                shift
                ;;
            "-ml")
                shift
                if [[ -z "$1" || "$1" == -* ]]; then
                    echo "Error: -ml requires a model ID argument"
                    return 1
                fi
                model="$1"
                model_arg="-ml"
                shift
                ;;
            *)
                # If template isn't set yet, this is the template
                if [[ -z "$template" ]]; then
                    template="$1"
                else
                    # Otherwise it's a model
                    model="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Check if template is provided
    if [[ -z "$template" ]]; then
        echo "Error: Missing template argument"
        echo "Usage: ${cmd} <template> [options]"
        return 1
    fi
    
    # Read ALL input at once
    local input
    input=$(cat)
    
    # Format the query with the input
    local formatted_query="${template//\{\}/$input}"
    
    # Handle different command cases
    if [[ "$cmd" == "tptn" ]]; then
        # Special handling for tptn's required -ml flag
        if [[ -z "$model" ]]; then
            echo "Error: tptn requires -ml flag for model specification"
            echo "Example: xtptn 'template' -ml modelname"
            return 1
        fi
        if $use_tor; then
            $cmd --tor -ml "$model" "$formatted_query"
        else
            $cmd -ml "$model" "$formatted_query"
        fi
    elif [[ "$cmd" == "tptg" ]]; then
        # Special handling for tptg with provider and model arguments
        if [[ -n "$provider" && -n "$model" ]]; then
            # Direct command execution with specified provider and model
            if $use_tor; then
                echo "Warning: --tor option is not supported for tptg. Ignoring."
            fi
            
            $cmd $provider_arg "$provider" $model_arg "$model" "$formatted_query"
        else
            # Interactive mode for tptg (existing behavior)
            if $use_tor; then
                echo "Warning: --tor option is not supported for tptg. Ignoring."
            fi
            
            if [[ -n "$model" && -z "$provider" ]]; then
                echo "Warning: For tptg, both -pr and -ml must be specified together"
                echo "Using interactive mode instead..."
            fi
            
            # Save the current stdin
            exec {STDIN_COPY}<&0
            
            # Redirect stdin from the terminal
            exec < /dev/tty
            
            echo "Your query: $formatted_query"
            echo "Please make your selections in the interactive menu:"
            echo ""
            
            # Run the command with the formatted query while stdin is connected to terminal
            $cmd "$formatted_query"
            
            # Restore original stdin
            exec 0<&${STDIN_COPY} {STDIN_COPY}<&-
        fi
    else
        if [[ -n "$model" ]]; then
            if $use_tor; then
                $cmd --tor "$model" "$formatted_query"
            else
                $cmd "$model" "$formatted_query"
            fi
        else
            if $use_tor; then
                $cmd --tor "$formatted_query"
            else
                $cmd "$formatted_query"
            fi
        fi
    fi
}

# Create functions for different providers
xtptc() { _xtgpt "tptc" "$@" }
xtptd() { _xtgpt "tptd" "$@" }
xtptp() { _xtgpt "tptp" "$@" }
xtptn() { _xtgpt "tptn" "$@" }
xtptg() { _xtgpt "tptg" "$@" }

setCFenv() {
  # Add timeout handling
  local timeout=5
  local cf_api_key
  local cf_account_id
  
  echo "Retrieving CloudFlare credentials..."
  
  # Use timeout command if available
  if command -v timeout >/dev/null 2>&1; then
    cf_api_key=$(timeout $timeout kwalletcli -f "cloudFlare_api" -e "CF_WAI_API_Key" 2>/dev/null)
    cf_account_id=$(timeout $timeout kwalletcli -f "cloudFlare_api" -e "CF_WAI_ACC" 2>/dev/null)
  else
    cf_api_key=$(kwalletcli -f "cloudFlare_api" -e "CF_WAI_API_Key" 2>/dev/null)
    cf_account_id=$(kwalletcli -f "cloudFlare_api" -e "CF_WAI_ACC" 2>/dev/null)
  fi

  # Verify both credentials were retrieved
  if [[ -z "$cf_api_key" || -z "$cf_account_id" ]]; then
    echo "Error: Failed to retrieve credentials from KWallet!"
    echo "Ensure:"
    echo "1. KWallet is unlocked"
    echo "2. Entries exist in 'cloudFlare_api' folder:"
    echo "   - CF_WAI_API_Key"
    echo "   - CF_WAI_ACC"
    return 1
  fi

  # Export to current shell session
  export CF_WAI_API_Key="$cf_api_key"
  export CF_WAI_ACC="$cf_account_id"

  # Confirm success (with partial key masking)
  echo "Cloudflare environment variables set:"
  echo "CF_WAI_ACC:    $CF_WAI_ACC"
  echo "CF_WAI_API_Key: ${CF_WAI_API_Key:0:4}****${CF_WAI_API_Key: -4}"
}

# AI-powered Git commit message generator
gitcommsg() {
    local model="o3"
    local context=""
    local chunk_mode=false
    local recursive_chunk=false
    local chunk_size=200
    local use_tor=false
    local use_nazapi=false
    local nazapi_model=""
    local use_g4f=false
    local g4f_provider=""
    local g4f_model=""
    local saved_provider=""
    local saved_model=""

    # Parse arguments first
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                # Help message display
                echo "Usage: gitcommsg [model] [-m message] [-c] [-cc] [--tor] [-ml MODEL] [--g4f] [-pr PROVIDER]"
                echo "Generate AI-powered commit messages from staged changes"
                echo ""
                echo "Options:"
                echo "  -m, --message  Additional context or priority message"
                echo "  -c, --chunk    Process large diffs in chunks (for 429 errors)"
                echo "  -cc, --chunk-recursive  Recursively chunk large commit messages"
                echo "  --tor         Route traffic through Tor network"
                echo "  -ml MODEL      Use custom model with nazOllama API (requires tptn)"
                echo "                 Or specify model ID with --g4f"
                echo "  --g4f         Use gpt4free interface via tptg"
                echo "  -pr PROVIDER   Specify provider ID for gpt4free (requires --g4f)"
                echo ""
                echo "Available models:"
                echo "  Online (default):"
                echo "    gpt/1, llama/2, claude/3, o3/4, mistral/5"
                echo "  nazOllama API (-ml):"
                echo "    Any model supported by tptn (e.g. deepseek-r1:14b)"
                echo "  gpt4free (--g4f):"
                echo "    Interactive selection or specify with -pr and -ml"
                echo ""
                echo "Examples:"
                echo "  gitcommsg                        # uses o3 (default)"
                echo "  gitcommsg llama                  # uses llama model"
                echo "  gitcommsg -m \"important fix\"     # adds context"
                echo "  gitcommsg claude -m \"refactor\"   # model + context"
                echo "  gitcommsg -ml deepseek-r1:14b      # uses nazOllama API with specified model"
                echo "  gitcommsg --tor -ml llama3.2:latest -m \"security fix\""
                echo "  gitcommsg --g4f                  # uses interactive gpt4free selection"
                echo "  gitcommsg --g4f -pr DDG -ml o3-mini # uses specific gpt4free provider/model"
                return 0
                ;;
            --g4f)
                use_g4f=true
                shift
                ;;
            --tor)
                use_tor=true
                shift
                ;;
            -m|--message)
                shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    echo "Error: -m/--message requires a non-empty message argument"
                    return 1
                fi
                context="$1"
                shift
                ;;
            -cc|--chunk-recursive)
                recursive_chunk=true
                chunk_mode=true
                shift
                ;;
            -c|--chunk)
                chunk_mode=true
                shift
                ;;
            -ml)
                shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    echo "Error: -ml requires a model name argument"
                    return 1
                fi
                if $use_g4f; then
                    g4f_model="$1"
                else
                    nazapi_model="$1"
                    use_nazapi=true
                fi
                shift
                ;;
            -pr)
                shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    echo "Error: -pr requires a provider ID argument"
                    return 1
                fi
                if ! $use_g4f; then
                    echo "Error: -pr can only be used with --g4f option"
                    return 1
                fi
                g4f_provider="$1"
                shift
                ;;
            *)
                # Validate model argument if not using g4f or nazapi
                if ! $use_g4f && ! $use_nazapi; then
                    case "$1" in
                        gpt|1|llama|2|claude|3|o3|4|mistral|5) 
                            model="$1"
                            shift
                            ;;
                        *)
                            echo "Error: Invalid model '$1' (valid: gpt/1, llama/2, claude/3, o3/4, mistral/5)"
                            return 1
                            ;;
                    esac
                else
                    echo "Error: Unexpected argument '$1'"
                    return 1
                fi
                ;;
        esac
    done

    # Validate g4f options
    if $use_g4f; then
        if [[ -n "$g4f_provider" && -z "$g4f_model" ]] || [[ -z "$g4f_provider" && -n "$g4f_model" ]]; then
            echo "Error: When using --g4f with manual selection, both -pr and -ml must be provided"
            return 1
        fi
    fi

    # Check if in a Git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Not a Git repository. Run this command from a Git project root."
        return 1
    fi

    # Moved staged changes validation AFTER help check
    if ! git diff --cached --quiet; then
        : # Changes exist, continue
    else
        echo "Error: No staged changes found. Stage changes with 'git add' first."
        return 1
    fi

    # Validate context length if provided
    if [[ -n "$context" && ${#context} -gt 100 ]]; then
        echo "Error: Context message too long (max 100 characters)"
        return 1
    fi

    local context_prompt=""
    if [[ -n "$context" ]]; then
        context_prompt="ABSOLUTE PRIORITY INSTRUCTION: \"$context\"

This user-provided context OVERRIDES any conflicting inference from the diff.
You MUST:
1. Use \"$context\" as the primary basis for the commit type and summary
2. Only use the git diff to identify WHAT changed (files, functions, etc.)
3. Focus bullet points on changes that support or relate to \"$context\"
4. If the diff contains changes unrelated to \"$context\", still prioritize 
   \"$context\"-related changes in your summary and bullets
5. Maintain the exact commit message format with proper types and detailed specifics

Example with context \"fix login flow\":
Even if the diff shows multiple changes, your commit message must focus on login flow fixes,
using other changes as supporting details only if relevant to the login flow.

"
    fi

    local template=''"$context_prompt"'   Analyze the following git diff and create a CONCISE but SPECIFIC commit message.
Format the message as:
type: <brief summary (max 50 chars)>

- [type] key change 1 (max 60 chars per line)
- [type] key change 2
- [type] key change N (include all significant changes)

GIT DIFF INTERPRETATION:
- The diff header "diff --git a/file1 b/file2" indicates files being compared
- For modified files:
  * "--- a/path" shows the original file (preimage)
  * "+++ b/path" shows the modified file (postimage)
- "@@" headers (e.g., "@@ -1,7 +1,6 @@") indicate line positions:
  * First number pair (-1,7): start line,count in preimage
  * Second number pair (+1,6): start line,count in postimage
- Prefixes indicate line status:
  * "+" lines are ADDED (appear in postimage only)
  * "-" lines are REMOVED (appear in preimage only)
  * " " lines are unchanged context (appear in both)
- Special status indicators in raw/patch headers:
  * "A": Addition of new file
  * "D": Deletion of file
  * "M": Modification to content/mode
  * "R": Rename with optional percentage (e.g., "R86%")
  * "C": Copy with similarity percentage
  * "T": Type change (regular file/symlink/submodule)
- For file mode changes, look for "mode change 100644 => 100755"
- For renamed/copied files, look for "rename from/to" or "copy from/to"
- Binary files show "Binary files differ" unless --binary option used
- Extended headers may show "similarity index" for renames/copies
- Index line shows blob hashes: "index fabadb8..4866510 100644"

Valid types (choose most specific):
- feat: New user features (not for new files without user features)
- fix: Bug fixes/corrections to errors
- refactor: Restructured code (no behavior change) 
- style: Formatting/whitespace changes
- docs: Documentation only
- test: Test-related changes
- perf: Performance improvements
- build: Build system changes
- ci: CI pipeline changes
- chore: Routine maintenance tasks
- revert: Reverting previous changes
- add: New files/resources with no user-facing features
- remove: Removing files/code
- update: Changes to existing functionality
- security: Security-related changes
- i18n: Internationalization
- a11y: Accessibility improvements
- api: API-related changes
- ui: User interface changes
- data: Database changes
- config: Configuration changes
- init: Initial commit/project setup

Rules:
1. FIRST carefully analyze what exactly changed in the diff:
   - Look at the --- and +++ lines to identify files
   - Examine "-" and "+" lines to understand exact changes
   - For modified lines, compare them directly
   - For code moves, notice similar patterns in different locations
2. Prefer specific types over generic ones (avoid "update" when something more specific applies)
3. If adding new file with user features, use "feat"; without user features use "add"
4. If text is edited, use "refactor" for logic changes or "style" for formatting
5. When removing something, check if it is deleted or moved elsewhere
6. For configuration files, prefer "config" over "update"
7. Keep summary under 50 chars (MANDATORY)
8. ALWAYS include specific details in each bullet point:
   - Filename (required - e.g., "auth/login.js")
   - Function name where applicable (e.g., "validateUser()")
   - Line number range if relevant (e.g., "lines 45-60")
   - Class name if OOP code (e.g., "UserAuth class")

EXAMPLE OUTPUT:
Given a diff where user-auth.js has error handling added and config.json timeout value changed:

fix: Improve auth error handling and increase timeout

- [fix] Add try/catch in user-auth.js:authenticateUser()
- [fix] Handle network errors in user-auth.js:loginCallback()
- [config] Increase API timeout from 3000ms to 5000ms in config.json

Git diff to analyze:
{}'

    local process_diff() {
        local diff_input="$1"
        local template="$2"
        local recursion_depth=0
        local max_recursion=3
        local ai_cmd="tptd"
        local ai_args=()

        # Determine which AI command to use
        if $use_g4f; then
            ai_cmd="tptg"
            # If provider and model are specified, use them
            if [[ -n "$g4f_provider" && -n "$g4f_model" ]]; then
                saved_provider="$g4f_provider"
                saved_model="$g4f_model"
                ai_args=("-pr" "$g4f_provider" "-ml" "$g4f_model")
            elif [[ -n "$saved_provider" && -n "$saved_model" ]]; then
                # Reuse previously selected provider and model
                ai_args=("-pr" "$saved_provider" "-ml" "$saved_model")
            elif [[ -n "$G4F_SELECTED_PROVIDER" && -n "$G4F_SELECTED_MODEL" ]]; then
                # Use previously exported variables from tptg
                saved_provider="$G4F_SELECTED_PROVIDER"
                saved_model="$G4F_SELECTED_MODEL"
                ai_args=("-pr" "$saved_provider" "-ml" "$saved_model")
                echo "Using previously selected provider '$saved_provider' and model '$saved_model'"
            fi
            # Otherwise, interactive selection will be used
        elif $use_nazapi; then
            ai_cmd="tptn"
            ai_args=("-ml" "$nazapi_model")
        fi
        
        # For interactive g4f, do a quick one-time selection via tptg
        if [[ "$ai_cmd" == "tptg" && ${#ai_args[@]} -eq 0 ]]; then
            echo "Running interactive provider/model selection via tptg..."
            
            # Create a temporary prompt to select provider/model
            local temp_prompt="This is a temporary prompt to select your provider and model."
            
            # Save the current stdin
            exec {STDIN_COPY}<&0
            
            # Redirect stdin from the terminal
            exec < /dev/tty
            
            # Enable exporting for the tptg call
            export G4F_EXPORT_ENABLED=1
            
            # Run tptg with a simple prompt to make selections
            echo "Please select a provider and model in the menu that appears:"
            echo "After selection is complete, the commit message generation will continue."
            echo ""
            
            # Run tptg without redirecting its output
            tptg "$temp_prompt"
            
            # Disable exporting after the call
            unset G4F_EXPORT_ENABLED
            
            # Restore original stdin
            exec 0<&${STDIN_COPY} {STDIN_COPY}<&-
            
            # Check if tptg exported the provider and model
            if [[ -n "$G4F_SELECTED_PROVIDER" && -n "$G4F_SELECTED_MODEL" ]]; then
                saved_provider="$G4F_SELECTED_PROVIDER"
                saved_model="$G4F_SELECTED_MODEL"
                ai_args=("-pr" "$saved_provider" "-ml" "$saved_model")
                echo "Selected provider: $saved_provider"
                echo "Selected model: $saved_model"
            else
                echo "Error: Provider and model selection failed"
                return 1
            fi
        fi
        
        if $chunk_mode; then
            echo "Processing diff in chunks (${chunk_size} lines)..."
            
            # Create temp directory
            local temp_dir=$(mktemp -d)
            trap "rm -rf $temp_dir" EXIT
            
            # Split diff into chunks
            echo "$diff_input" | split -l $chunk_size - "$temp_dir/chunk_"
            
            local chunk_count=$(ls "$temp_dir" | wc -l)
            echo "Found $chunk_count chunks to process"
            
            # Process each chunk
            local i=1
            for chunk in "$temp_dir"/chunk_*; do
                echo "\n=== CHUNK $i/$chunk_count ==="
                echo "Raw diff lines: $(wc -l < "$chunk")"
                local chunk_template="Analyze this PARTIAL git diff and create a commit message summary with this exact format:
[FILES]: Comma-separated affected files
[CHANGES]: Bullet points of technical changes (max 3)
[IMPACT]: One line describing user-facing impact

Diff chunk:\n{}"
                
                echo "\n🚧 Partial analysis:"
                local max_retries=3
                local retry_count=0
                local wait_seconds=10
                
                while true; do
                    local tmpfile=$(mktemp)
                    local cmd_status=0

                    # Execute the appropriate command with or without tor
                    if $use_tor && ! $use_g4f; then
                        # G4F doesn't support tor directly
                        if [[ ${#ai_args[@]} -gt 0 ]]; then
                            $ai_cmd --tor "${ai_args[@]}" "$chunk_template" < "$chunk" | tee "$tmpfile"
                        else
                            $ai_cmd --tor "$model" "$chunk_template" < "$chunk" | tee "$tmpfile"
                        fi
                    else
                        # Normal execution with saved args
                        if [[ ${#ai_args[@]} -gt 0 ]]; then
                            $ai_cmd "${ai_args[@]}" "$chunk_template" < "$chunk" | tee "$tmpfile"
                        else
                            $ai_cmd "$model" "$chunk_template" < "$chunk" | tee "$tmpfile"
                        fi
                        cmd_status=${pipestatus[1]}
                    fi
                    
                    if [ $cmd_status -eq 0 ]; then
                        cat "$tmpfile" >> "$temp_dir/partials.txt"
                        break
                    else
                        ((retry_count++))
                        if [ $retry_count -gt $max_retries ]; then
                            rm -f "$tmpfile"
                            echo "❌ Failed after $max_retries retries. Aborting."
                            return 1
                        fi
                        
                        echo -n "⚠️  Error (attempt $retry_count/$max_retries). Waiting ${wait_seconds}s... "
                        local spin='⣷⣯⣟⡿⢿⣻⣽⣾'
                        local start_time=$SECONDS
                        while (( (SECONDS - start_time) < wait_seconds )); do
                            echo -n "${spin:0:1}"
                            spin="${spin:1}${spin:0:1}"
                            sleep 0.2
                            echo -ne "\b"
                        done
                        echo -e "\r🔄 Retrying...    "
                        
                        # Exponential backoff
                        wait_seconds=$((wait_seconds * 2))
                    fi
                    rm -f "$tmpfile"
                done
                
                ((i++))
                
                # Rate limit protection
                if ((i < chunk_count)); then
                    echo -n "⏳ Pausing 10s "
                    local spin='⣷⣯⣟⡿⢿⣻⣽⣾'
                    local start_time=$SECONDS
                    while (( (SECONDS - start_time) < 10 )); do
                        echo -n "${spin:0:1}"
                        spin="${spin:1}${spin:0:1}"
                        sleep 0.2
                        echo -ne "\b"
                    done
                    echo -e "\r✅ Continued.   "
                fi
            done
            
            echo "\n📦 Collected partial analyses:"
            cat "$temp_dir/partials.txt"
            
            # Combine partial results
            echo "\n🔨 Combining partial analyses..."
            local combine_template="Synthesize this commit message from partial analyses (iteration $((recursion_depth + 1))):
$(cat "$temp_dir/partials.txt")

Rules:
1. Group changes by category (docs, feat, fix, etc)
2. Prioritize user-facing changes
3. Keep bullets under 60 chars
4. Follow conventional commit format

Final message:"
            diff_input="$combine_template"
            
            # Recursive chunking for large messages
            if $recursive_chunk && (( recursion_depth < max_recursion )); then
                local msg_length=$(echo "$diff_input" | wc -l)
                local msg_threshold=50
                
                while (( msg_length > msg_threshold )) && (( recursion_depth < max_recursion )); do
                    echo "\n⚠️  Combined message too long (${msg_length} lines), re-chunking..."
                    ((recursion_depth++))
                    
                    # Process the long message as new input
                    diff_input=$(process_diff "$diff_input" "$template")
                    msg_length=$(echo "$diff_input" | wc -l)
                    
                    echo "\n🔄 Recursion depth $recursion_depth - New length: ${msg_length} lines"
                done
            fi
        fi

        echo "\n🎉 Final commit message generation..."
        # Final command execution with tor support or g4f
        if $use_g4f; then
            $ai_cmd -pr "$saved_provider" -ml "$saved_model" "$template" <<< "$diff_input"
        elif $use_tor; then
            if $use_nazapi; then
                $ai_cmd --tor "${ai_args[@]}" "$template" <<< "$diff_input"
            else
                $ai_cmd --tor "$model" "$template" <<< "$diff_input"
            fi
        else
            if $use_nazapi; then
                $ai_cmd "${ai_args[@]}" "$template" <<< "$diff_input"
            else
                $ai_cmd "$model" "$template" <<< "$diff_input"
            fi
        fi
    }

    # Capture diff and process
    local diff_content=$(git diff --staged)
    if ! process_diff "$diff_content" "$template"; then
        # Clean up environment variables even on failure
        unset G4F_SELECTED_PROVIDER
        unset G4F_SELECTED_MODEL
        return 1
    fi
    
    # Clean up environment variables when done
    unset G4F_SELECTED_PROVIDER
    unset G4F_SELECTED_MODEL
}

# AI-powered text rewriter that preserves tone
rewrite() {
    local model="o3"
    local use_tor=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            "--tor")
                use_tor=true
                shift
                ;;
            "--help"|"-h")
                echo "Usage: rewrite [--tor] [model]"
                echo "Rewrite text to be more natural while preserving tone"
                echo ""
                echo "Options:"
                echo "  --tor        Route traffic through Tor network"
                echo ""
                echo "Available models (same as tptd):"
                echo "  gpt, 1     : gpt-4o-mini"
                echo "  llama, 2   : Llama-3.3-70B-Instruct-Turbo"
                echo "  claude, 3  : claude-3-haiku-20240307"
                echo "  o3, 4      : o3-mini"
                echo "  mistral, 5 : Mistral-Small-24B-Instruct-2501"
                echo ""
                echo "Examples:"
                echo "  echo \"your text\" | rewrite"
                echo "  echo \"angry message\" | rewrite --tor llama"
                echo "  cat file.txt | rewrite --tor claude"
                echo ""
                echo "Default: o3"
                return 0
                ;;
            gpt|1|llama|2|claude|3|o3|4|mistral|5)
                model="$1"
                shift
                break
                ;;
            *)
                echo "Error: Invalid model '$1'"
                echo "Valid models: gpt/1, llama/2, claude/3, o3/4, mistral/5"
                return 1
                ;;
        esac
    done

    if [[ -t 0 || ! -p /dev/stdin ]]; then
        echo "Error: No input provided. Use pipe to provide text."
        echo "Example: echo \"text\" | rewrite [--tor] [model]"
        return 1
    fi

    local template="Rewrite the following text to be more natural and grammatically correct.
Important rules:
1. Preserve the original tone (angry, happy, sorry, formal, etc)
2. Fix grammar and spelling errors
3. Make it flow more naturally
4. Keep the same meaning and intent
5. Do not change the level of politeness/rudeness
6. Do not add or remove main points
7. Specific guidelines:
   a. Convert passive voice to active voice where appropriate
   b. Break up long sentences (max 25 words) but maintain pacing
   c. Replace jargon with simpler terms when possible
   d. Maintain technical terms when crucial to meaning
   e. Fix misplaced modifiers and dangling participles
   f. Ensure pronoun references are clear
   g. Keep lists parallel in structure
   h. Preserve any markdown/code formatting
8. Handle special cases:
   - Preserve code samples between \`\`\` unchanged
   - Maintain quoted text integrity
   - Keep placeholders like {variable} intact
   - Preserve URLs and email addresses
   - Maintain original paragraph breaks and newlines
   - Only remove line breaks if they create awkward spacing
   - Preserve list formatting (bullets/numbers)
   - Keep related ideas in the same paragraph

Examples of GOOD rewrites:
Original: \"The system, it should be noted, when in operation, may experience lags.\"
Rewritten: \"The system might experience delays during operation.\"

Original: \"We was planning to done the task yesterday but it weren't possible.\"
Rewritten: \"We had planned to complete the task yesterday, but it wasn't possible.\"

Text to rewrite: {}"

    # Process with tptd
    if $use_tor; then
        tptd --tor "$model" "$template"
    else
        tptd "$model" "$template"
    fi
}

