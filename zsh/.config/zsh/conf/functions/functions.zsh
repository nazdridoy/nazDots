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
    
    # Define color codes
    local BLUE='\033[0;34m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local CYAN='\033[0;36m'
    local PURPLE='\033[0;35m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m' # No Color
    
    # Parse arguments - options must come before the prompt
    while [[ $# -gt 1 ]]; do
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
            "--help"|"-h")
                echo -e "${BOLD}Usage:${NC} tptg [options] <query>"
                echo ""
                echo -e "${BOLD}Options:${NC}"
                echo -e "  -pr <provider_id> : Specify provider ID directly"
                echo -e "  -ml <model_id>    : Specify model ID directly"
                echo -e "  --help, -h        : Show this help message"
                echo ""
                echo -e "${BOLD}Example:${NC}"
                echo -e "  tptg \"What is quantum computing?\""
                echo -e "  tptg -pr DDG -ml o3-mini \"What is quantum computing?\""
                echo ""
                echo -e "${YELLOW}Note:${NC}"
                echo -e "  1. The prompt must be the last argument"
                echo -e "  2. Requires a local gpt4free instance running at http://localhost:1337"
                return 0
                ;;
            *)
                echo -e "${RED}Error:${NC} Invalid option '$1'"
                echo -e "Usage: tptg [options] <query>"
                echo -e "Run 'tptg --help' for more information"
                return 1
                ;;
        esac
    done
    
    # The last argument is the prompt
    if [[ $# -eq 1 ]]; then
        prompt="$1"
    else
        echo -e "${RED}Error:${NC} No prompt provided"
        echo -e "Usage: tptg [options] <query>"
        return 1
    fi
    
    # Check if both provider and model are provided to skip interactive selection
    if [[ -n "$provider" && -n "$model" ]]; then
        skip_interactive=true
    elif [[ -n "$provider" || -n "$model" ]]; then
        # Error if only one of -pr or -ml is provided
        echo -e "${RED}Error:${NC} Both -pr and -ml must be specified together"
        echo -e "Example: tptg -pr DDG -ml o3-mini \"What is quantum computing?\""
        return 1
    fi
    
    # Check if prompt is provided (should be redundant now)
    if [[ -z "$prompt" ]]; then
        echo -e "${RED}Error:${NC} No prompt provided"
        echo -e "Usage: tptg [options] <query>"
        return 1
    fi
    
    # Check if gpt4free server is running
    if ! curl -s "$base_url/v1/models" > /dev/null; then
        echo -e "${RED}Error:${NC} Cannot connect to gpt4free server at $base_url"
        echo -e "Make sure the server is running and accessible"
        return 1
    fi
    
    # Function to clear screen and show header
    clear_and_show_header() {
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
    
    # Run tgpt with the selected provider and model
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    echo -e "${BOLD}${BLUE}| ${CYAN}Using provider:${NC} ${GREEN}$provider${NC}"
    echo -e "${BOLD}${BLUE}| ${CYAN}Using model:${NC} ${GREEN}$model${NC}"
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    echo -e "${YELLOW}Sending request...${NC}"
    tgpt --provider openai \
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

## tgpt with local Ollama
tpto() {
    local model="llama3.2:latest"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "${1:-}" in
            "deepseek"|"1")
                model="deepseek-r1:1.5b"
                shift
                ;;
            "qwen3b"|"2")
                model="qwen2.5-coder:3b"
                shift
                ;;
            "qwen7b"|"3")
                model="qwen2.5-coder:7b"
                shift
                ;;
            "llama3"|"4")
                model="llama3.2:latest"
                shift
                ;;
            "gemma"|"5")
                model="gemma2:2b"
                shift
                ;;
            "--help"|"-h")
                echo "Usage: tpto [model] <query>"
                echo "Available models:"
                echo "  deepseek, 1 : deepseek-r1:1.5b"
                echo "  qwen3b, 2   : qwen2.5-coder:3b"
                echo "  qwen7b, 3   : qwen2.5-coder:7b"
                echo "  llama3, 4   : llama3.2:latest"
                echo "  gemma, 5    : gemma2:2b"
                echo "Default: llama3.2:latest"
                echo ""
                echo "Note: Requires Ollama server running and model downloaded locally."
                echo "      Run 'ollama serve' and 'ollama pull <model>' if needed."
                return 0
                ;;
            *)
                break
                ;;
        esac
    done

    # Check Ollama installation
    if ! command -v ollama >/dev/null 2>&1; then
        echo "Error: Ollama not found. Install from https://ollama.ai/download"
        return 1
    fi

    # Check if Ollama server is running
    if ! ollama list >/dev/null 2>&1; then
        echo "Error: Ollama server not running. Start with: ollama serve"
        echo "Note: Keep the serve session running in another terminal"
        return 1
    fi

    # Verify model exists locally
    local model_exists=$(ollama list | awk '{print $1}' | grep -w "${model%%:*}")
    if [[ -z "$model_exists" ]]; then
        echo "Error: Model '${model%%:*}' not found in local Ollama library"
        echo "Available models:"
        ollama list
        echo "\nInstall with: ollama pull ${model%%:*}"
        return 1
    fi

    tgpt --provider ollama --model "$model" "$@"
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
    # Display help message if --help or -h is passed
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: xtptp/xtptd/xtptc/xtpto <template> [--tor] [model]"
        echo ""
        echo "Replace placeholders in the template with input and execute the command."
        echo ""
        echo "Arguments:"
        echo "  <template>    A text template with placeholders (e.g. 'hello {}, how are you?')"
        echo "  --tor        Route traffic through Tor network (not for xtpto)"
        echo "  [model]       For xtptd: model number (1-5) or name (gpt/llama/claude/o3/mistral)"
        echo "                For xtptc: model number (1-3) or name (llama/deepseek/llama70b)"
        echo "                For xtpto: model number (1-5) or name (deepseek/qwen3b/qwen7b/llama3/gemma)"
        echo ""
        echo "Example:"
        echo "  echo \"Vscode\" | xtptd \"what is {}, can it play music?\" --tor claude"
        echo "  echo \"Python\" | xtptc \"explain {} in simple terms\" --tor llama70b"
        echo "  echo \"Docker\" | xtpto \"how to optimize {} containers?\" llama3"
        echo ""
        return 0
    fi

    local cmd="$1"
    local template=""
    shift  # Remove the command name from arguments

    # Check if template is provided
    if [[ $# -eq 0 || "$1" == -* ]]; then
        echo "Error: Missing template argument"
        echo "Usage: ${cmd} <template> [options]"
        return 1
    fi
    template="$1"
    shift  # Remove template from arguments

    # Read ALL input at once instead of line-by-line
    local input
    input=$(cat)

    # Handle --tor option for supported commands
    local use_tor=false
    local model=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            "--tor")
                if [[ "$cmd" != "tpto" ]]; then
                    use_tor=true
                else
                    echo "Warning: --tor option not supported for xtpto (local Ollama)"
                fi
                shift
                ;;
            *)
                model="$1"
                shift
                ;;
        esac
    done

    # Build the command with appropriate options
    if [[ "$cmd" == "tptn" ]]; then
        # Special handling for tptn's required -ml flag
        if [[ -z "$model" ]]; then
            echo "Error: tptn requires -ml flag for model specification"
            echo "Example: xtptn 'template' -ml modelname"
            return 1
        fi
        if $use_tor; then
            $cmd --tor -ml "$model" "${template//\{\}/$input}"
        else
            $cmd -ml "$model" "${template//\{\}/$input}"
        fi
    elif [[ "$cmd" == "tptg" ]]; then
        # Special handling for tptg which uses an interactive menu
        if $use_tor; then
            echo "Warning: --tor option is not supported for tptg. Ignoring."
        fi
        
        if [[ -n "$model" ]]; then
            echo "Warning: Model selection ('$model') is not supported for tptg. Ignoring."
            echo "tptg uses an interactive menu for provider/model selection."
        fi
        
        # Format the query with the input
        local formatted_query="${template//\{\}/$input}"
        
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
    else
        if [[ -n "$model" ]]; then
            if $use_tor; then
                $cmd --tor "$model" "${template//\{\}/$input}"
            else
                $cmd "$model" "${template//\{\}/$input}"
            fi
        else
            if $use_tor; then
                $cmd --tor "${template//\{\}/$input}"
            else
                $cmd "${template//\{\}/$input}"
            fi
        fi
    fi
}

# Create functions for different providers
xtptc() { _xtgpt "tptc" "$@" }
xtptd() { _xtgpt "tptd" "$@" }
xtptp() { _xtgpt "tptp" "$@" }
xtpto() { _xtgpt "tpto" "$@" }
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
    local use_offline=false
    local use_tor=false
    local use_nazapi=false
    local nazapi_model=""

    # Check if --offline is used but not as first argument
    if [[ " $@ " =~ " --offline " && "$1" != "--offline" ]]; then
        echo "Error: --offline must be the first argument if using offline mode"
        return 1
    fi

    # Parse arguments first
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                # Help message display
                echo "Usage: gitcommsg [model] [-m message] [-c] [-cc] [--tor] [--offline] [-ml MODEL]"
                echo "Generate AI-powered commit messages from staged changes"
                echo ""
                echo "Options:"
                echo "  -m, --message  Additional context or priority message"
                echo "  -c, --chunk    Process large diffs in chunks (for 429 errors)"
                echo "  -cc, --chunk-recursive  Recursively chunk large commit messages"
                echo "  --offline      Use local Ollama model instead of online provider"
                echo "  --tor         Route traffic through Tor network (not for offline mode)"
                echo "  -ml MODEL      Use custom model with nazOllama API (requires tptn)"
                echo ""
                echo "Available models:"
                echo "  Online (default):"
                echo "    gpt/1, llama/2, claude/3, o3/4, mistral/5"
                echo "  nazOllama API (-ml):"
                echo "    Any model supported by tptn (e.g. deepseek-r1:14b)"
                echo "  Offline (with --offline):"
                echo "    deepseek/1, qwen3b/2, qwen7b/3, llama3/4, gemma/5"
                echo ""
                echo "Examples:"
                echo "  gitcommsg                        # uses o3 (default)"
                echo "  gitcommsg llama                  # uses llama model"
                echo "  gitcommsg -m \"important fix\"     # adds context"
                echo "  gitcommsg claude -m \"refactor\"   # model + context"
                echo "  gitcommsg --offline llama3 -c    # offline with chunking"
                echo "  gitcommsg --offline deepseek -m \"security patch\""
                echo "  gitcommsg -ml deepseek-r1:14b      # uses nazOllama API with specified model"
                echo "  gitcommsg --tor -ml llama3.2:latest -m \"security fix\""
                return 0
                ;;
            --tor)
                use_tor=true
                shift
                ;;
            --offline)
                use_offline=true
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
                if $use_offline; then
                    echo "Error: -ml cannot be used with --offline mode"
                    return 1
                fi
                shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    echo "Error: -ml requires a model name argument"
                    return 1
                fi
                nazapi_model="$1"
                use_nazapi=true
                shift
                ;;
            *)
                # Validate model argument
                if $use_offline; then
                    case "$1" in
                        deepseek|1|qwen3b|2|qwen7b|3|llama3|4|gemma|5)
                            model="$1"
                            shift
                            ;;
                        *)
                            echo "Error: Invalid offline model '$1' (valid: deepseek/1, qwen3b/2, qwen7b/3, llama3/4, gemma/5)"
                            return 1
                            ;;
                    esac
                else
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
                fi
                ;;
        esac
    done

    # Check if --tor and --offline are used together
    if $use_tor && $use_offline; then
        echo "Error: --tor cannot be used with --offline mode"
        return 1
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
        context_prompt="CRITICAL INSTRUCTION: The following user request takes priority: \"$context\"

While analyzing the git diff, ensure your response primarily reflects this request.
The git diff should only inform additional details if they align with the request.
Format your response according to the commit message rules, but make \"$context\" 
the main focus of the message.

"
    fi

    local template=''"$context_prompt"'   Analyze the following git diff and create a CONCISE but SPECIFIC commit message.
Format the message as:
type: <brief summary (max 50 chars)>

- [type] key change 1 (max 60 chars per line)
- [type] key change 2
- [type] key change N (include all significant changes)

Valid types (use most specific applicable):
- feat: New user-facing features
- add: Added new files/resources
- update: Updates to existing features
- remove: Removed files/features
- fix, bugfix: Bug fixes
- hotfix: Critical fixes
- docs: Documentation changes
- style: Code style/formatting (non-functional)
- ui: User interface changes
- refactor: Code restructuring (no behavior change)
- perf: Performance improvements
- test: Testing changes
- build: Build system changes
- ci: CI/CD changes
- deploy: Deployment/release
- deps: Dependency updates
- chore: Maintenance tasks
- revert: Reverts previous changes
- wip: Work in progress
- security: Security-related changes
- i18n: Internationalization/localization
- a11y: Accessibility improvements
- data: Database/schema changes
- config: Configuration changes
- api: API-related changes
- init: Initial commit/project setup

Rules:
1. Summary MUST be under 50 chars - truncate if needed
2. Each bullet point must:
   - Start with [type] where type matches changes
   - Mention specific files/functions/endpoints (e.g. "auth/login.js")
   - Explain WHAT changed, not just why
   - Keep under 60 chars
3. Prioritize these aspects:
   a. Security-related changes
   b. Breaking API changes
   c. New features
   d. Bug fixes
4. For moved code: Use "moved X to Y" not just "changed X"
5. For whitespace changes: Only mention if significant (e.g. indentation fixes)
6. Group similar changes (e.g. "Update tests for X and Y")
7. Never include:
   - File permissions changes
   - Comments-only changes
   - Whitespace-only changes (unless rule 5 applies)
   - Package manager internals (lock files)

Examples of GOOD messages:
1. fix: Resolve login page CSS overflow

- [fix] Fix mobile menu overflow in static/css/main.css
- [ui] Adjust padding on .auth-container in login.html
- [test] Add viewport meta tag to login test cases

2. feat: Add user profile export endpoint

- [feat] New /api/v1/users/export endpoint in routes/users.js
- [security] Add rate limiting to export endpoint (5/min)
- [api] Include export_status field in GET /profile response
- [docs] Update API reference with export endpoint details

Git diff to analyze:
{}'

    local process_diff() {
        local diff_input="$1"
        local template="$2"
        local recursion_depth=0
        local max_recursion=3
        local ai_cmd="tptd"
        if $use_offline; then
            ai_cmd="tpto"
        elif $use_nazapi; then
            ai_cmd="tptn"
            ai_args=("-ml" "$nazapi_model")
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
                    if $use_tor && ! $use_offline; then
                        if $use_nazapi; then
                            $ai_cmd --tor "${ai_args[@]}" "$chunk_template" < "$chunk" | tee "$tmpfile"
                        else
                            $ai_cmd --tor "$model" "$chunk_template" < "$chunk" | tee "$tmpfile"
                        fi
                    else
                        if $use_nazapi; then
                            $ai_cmd "${ai_args[@]}" "$chunk_template" < "$chunk" | tee "$tmpfile"
                        else
                            $ai_cmd "$model" "$chunk_template" < "$chunk" | tee "$tmpfile"
                        fi
                    fi
                    cmd_status=${pipestatus[1]}
                    
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
        # Final command execution with tor support
        if $use_tor && ! $use_offline; then
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
        return 1
    fi
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

