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
tptb() {
    local model="o3-mini"  # Set default model first
    local use_tor=false
    local base_url="http://localhost:1337"
    local tgpt_args=()  # Array to store tgpt arguments
    local prompt=""

    # Check if G4F environment variables are set
    if [[ -n "$G4F_PROVIDER" && -n "$G4F_MODEL" ]]; then
        # Parse arguments - looking for flags and the prompt
        while [[ $# -gt 0 ]]; do
            case "${1:-}" in
                "--tor")
                    use_tor=true
                    shift
                    ;;
                "--help"|"-h")
                    echo "Usage: tptb [--tor] [-flags] <query>"
                    echo "Using G4F environment settings:"
                    echo "  Provider: $G4F_PROVIDER"
                    echo "  Model: $G4F_MODEL"
                    echo ""
                    echo "Options:"
                    echo "  --tor      : Route traffic through Tor network"
                    echo "  All tgpt flags are supported (-s, -i, -q, etc.)"
                    return 0
                    ;;
                -*)
                    # Collect all tgpt flags
                    tgpt_args+=("$1")
                    shift
                    ;;
                *)
                    # Everything else becomes part of the prompt
                    if [[ -z "$prompt" ]]; then
                        prompt="$1"
                    else
                        prompt="$prompt $1"
                    fi
                    shift
                    ;;
            esac
        done

        if $use_tor; then
            if ! command -v torify >/dev/null 2>&1; then
                echo "Error: torify not found. Please install tor package."
                return 1
            fi
            torify tgpt --provider openai \
                --url "$base_url/api/$G4F_PROVIDER/chat/completions" \
                --model "$G4F_MODEL" \
                "${tgpt_args[@]}" \
                "$prompt"
        else
            tgpt --provider openai \
                --url "$base_url/api/$G4F_PROVIDER/chat/completions" \
                --model "$G4F_MODEL" \
                "${tgpt_args[@]}" \
                "$prompt"
        fi
        return
    fi

    # Original tptb functionality if G4F env is not set
    while [[ $# -gt 0 ]]; do
        case "${1:-}" in
            "--tor")
                use_tor=true
                shift
                ;;
            "gpt4o-mini"|"1")
                model="gpt-4o-mini"
                shift
                ;;
            "gpt4o"|"2")
                model="GPT-4o"
                shift
                ;;
            "o1"|"3")
                model="o1"
                shift
                ;;
            "o3"|"4")
                model="o3-mini"
                shift
                ;;
            "claude37"|"5")
                model="Claude-sonnet-3.7"
                shift
                ;;
            "claude35"|"6")
                model="Claude-sonnet-3.5"
                shift
                ;;
            "deepseekv3"|"7")
                model="DeepSeek-V3"
                shift
                ;;
            "deepseekr1"|"8")
                model="DeepSeek-R1"
                shift
                ;;
            "--help"|"-h")
                echo "Usage: tptb [--tor] [model] <query>"
                echo "Available models:"
                echo "  gpt4o-mini, 1  : gpt-4o-mini"
                echo "  gpt4o, 2      : GPT-4o"
                echo "  o1, 3         : o1"
                echo "  o3, 4         : o3-mini"
                echo "  claude37, 5   : Claude-sonnet-3.7"
                echo "  claude35, 6   : Claude-sonnet-3.5"
                echo "  deepseekv3, 7 : DeepSeek-V3"
                echo "  deepseekr1, 8 : DeepSeek-R1"
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

    if $use_tor; then
        if ! command -v torify >/dev/null 2>&1; then
            echo "Error: torify not found. Please install tor package."
            return 1
        fi
        torify tgpt --provider openai \
            --url "$base_url/api/Blackbox/chat/completions" \
            --model "$model" \
            "$@"
    else
        tgpt --provider openai \
            --url "$base_url/api/Blackbox/chat/completions" \
            --model "$model" \
            "$@"
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
        echo "Usage: xtptp/xtptb/xtptc/xtptn/xtptg <template> [--tor] [model]"
        echo ""
        echo "Replace placeholders in the template with input and execute the command."
        echo ""
        echo "Arguments:"
        echo "  <template>    A text template with placeholders (e.g. 'hello {}, how are you?')"
        echo "  --tor        Route traffic through Tor network"
        echo "  [model]       For xtptb: model number (1-5) or name (gpt/llama/claude/o3/mistral)"
        echo "                For xtptc: model number (1-3) or name (llama/deepseek/llama70b)"
        echo "                For xtptn: Use -ml <modelname> to specify model"
        echo "                For xtptg: Use -pr <provider> -ml <model> to specify provider and model"
        echo ""
        echo "Example:"
        echo "  echo \"Vscode\" | xtptb \"what is {}, can it play music?\" --tor claude"
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
xtptb() { _xtgpt "tptb" "$@" }
xtptp() { _xtgpt "tptp" "$@" }
xtptn() { _xtgpt "tptn" "$@" }
xtptg() { _xtgpt "tptg" "$@" }

## Set CloudFlare environment variables
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

## Set Gemini environment variables
setGeminiEnv() {
  # Add timeout handling
  local timeout=5
  local gemini_api_key
  
  echo "Retrieving Gemini API key..."
  
  # Use timeout command if available
  if command -v timeout >/dev/null 2>&1; then
    gemini_api_key=$(timeout $timeout kwalletcli -f "gemini-api" -e "GEMINI_API" 2>/dev/null)
  else
    gemini_api_key=$(kwalletcli -f "gemini-api" -e "GEMINI_API" 2>/dev/null)
  fi

  # Verify the API key was retrieved
  if [[ -z "$gemini_api_key" ]]; then
    echo "Error: Failed to retrieve Gemini API key from KWallet!"
    echo "Ensure:"
    echo "1. KWallet is unlocked"
    echo "2. Entry exists in 'gemini-api' folder:"
    echo "   - GEMINI_API"
    return 1
  fi

  # Export to current shell session
  export GEMINI_API="$gemini_api_key"

  # Confirm success (with partial key masking)
  echo "Gemini environment variable set:"
  echo "GEMINI_API: ${GEMINI_API:0:4}****${GEMINI_API: -4}"
}

## Set G4F environment variables
setG4Fenv() {
    local provider=""
    local model=""
    local base_url="http://localhost:1337"
    
    # Define color codes
    local BLUE='\033[0;34m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local CYAN='\033[0;36m'
    local PURPLE='\033[0;35m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m' # No Color
    
    # Check if gpt4free server is running
    if ! curl -s "$base_url/v1/models" > /dev/null; then
        echo -e "${RED}Error:${NC} Cannot connect to gpt4free server at $base_url"
        echo -e "Make sure the server is running and accessible"
        return 1
    fi
    
    # Clear screen and show header
    clear
    printf "\033c"  # ANSI escape sequence to reset terminal
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    echo -e "${BOLD}${BLUE}|       ${CYAN}G4F Provider Selection${BLUE}         |${NC}"
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    
    # Provider selection loop
    while true; do
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
        clear
        printf "\033c"
        echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
        echo -e "${BOLD}${BLUE}|       ${CYAN}G4F Model Selection${BLUE}            |${NC}"
        echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
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
        break
    done
    
    # Export the selected provider and model
    export G4F_PROVIDER="$provider"
    export G4F_MODEL="$model"
    
    # Show confirmation
    clear
    printf "\033c"
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    echo -e "${BOLD}${BLUE}|       ${CYAN}G4F Settings Exported${BLUE}           |${NC}"
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    echo -e "${BOLD}Exported variables:${NC}"
    echo -e "${CYAN}G4F_PROVIDER:${NC} ${GREEN}'$provider'${NC}"
    echo -e "${CYAN}G4F_MODEL:${NC} ${GREEN}'$model'${NC}"
}