########################################################
#####            Custom Function Define            #####
########################################################

# Function for Compiling Plugins to byte code 
function plugin-compile {
  OMZPlugins=$ZSH_CUSTOM
  OMZBPlugins=$ZSH/plugins
  OMZlibs=$ZSH/lib
  ZSHCONFIGX=$ZDOTDIR/conf
  autoload -U zrecompile
  local o
  for o in $OMZPlugins/**/**/*.zsh{,-theme}(N); do
    zrecompile -pq "$o"
  done
  local z
  for z in $ZSHCONFIGX/**/*.zsh{,-theme}(N); do
    zrecompile -pq "$z"
  done
  local b
  for b in $OMZBPlugins/**/*.zsh{,-theme}(N); do
    zrecompile -pq "$b"
  done
  local l
  for l in $OMZlibs/**/*.zsh{,-theme}(N); do
    zrecompile -pq "$l"
  done  
}



# Open scripts by its name
nvis () {
  nvim $(which $1)
}

# w3m DuckDuckGo Search Function
duck () {
  w3m "duckduckgo.com/lite?q=$*"
}
# w3m Google Search Function 
google () {
 w3m "google.com/search?&q=$*"
}
# w3m Searx.be Search Function 
searx () {
 w3m "https://searx.be/search?q=$*"
}
# w3m "command-not-found.com" Search Function
cmdntfound () {
  w3m "https://command-not-found.com/$*"
}
# w3m "cheat.sh Search Function
cht.sh (){
   w3m "cht.sh/$*"
}

# cheat.sh Function
cht() { 
  curl cheat.sh/$1
}

# Create a directory and change into it at the same time
mkd() {
 mkdir -p "$@"
 if [ "$#" -gt 1 ]; then
    selected_dir=$(echo "$@" | tr ' ' '\n' | fzf)
    cd "$selected_dir"
 else
    cd "$1"
 fi
}



# tgpt Functions
## tgpt with phind

tptp() {
    tgpt --provider phind "$@"
} 

## tgpt with duckduckgo provider and multiple models
tptd() {
    local model=""
    case "${1:-}" in
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
            echo "Usage: tptd [model] <query>"
            echo "Available models:"
            echo "  gpt, 1     : gpt-4o-mini"
            echo "  llama, 2   : Llama-3.3-70B-Instruct-Turbo"
            echo "  claude, 3  : claude-3-haiku-20240307"
            echo "  o3, 4      : o3-mini"
            echo "  mistral, 5 : Mistral-Small-24B-Instruct-2501"
            echo "Default: o3-mini"
            return 0
            ;;
        *)
            model="o3-mini"
            ;;
    esac
    
    tgpt --provider duckduckgo --model "$model" "$@"
}

## tgpt with CloudFlare AI API
tptc() {
    local model=""
    case "${1:-}" in
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
            echo "Usage: tptc [model] <query>"
            echo "Available models:"
            echo "  llama, 1     : @cf/meta/llama-3.1-8b-instruct"
            echo "  deepseek, 2  : @cf/deepseek-ai/deepseek-r1-distill-qwen-32b"
            echo "  llama70b, 3  : @cf/meta/llama-3.3-70b-instruct-fp8-fast"
            echo "Default: @cf/meta/llama-3.1-8b-instruct"
            echo ""
            echo "Note: Requires CloudFlare credentials. Run setCFenv first."
            return 0
            ;;
        *)
            model="@cf/meta/llama-3.1-8b-instruct"
            ;;
    esac
    
    # Check if CloudFlare environment variables are set (only when making a query)
    if [[ -z "$CF_WAI_API_Key" || -z "$CF_WAI_ACC" ]]; then
        echo "Error: CloudFlare credentials not set. Run setCFenv first."
        return 1
    fi
    
    tgpt --provider openai \
         --url "https://api.cloudflare.com/client/v4/accounts/${CF_WAI_ACC}/ai/v1/chat/completions" \
         --model "$model" \
         --key "${CF_WAI_API_Key}" \
         "$@"
}

# Generic template function for tgpt commands
_xtgpt() {
    # Display help message if --help or -h is passed
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: xtptp/xtptd/xtptc <template> [model]"
        echo ""
        echo "Replace placeholders in the template with input and execute the command."
        echo ""
        echo "Arguments:"
        echo "  <template>    A text template with placeholders (e.g., 'hello {}, how are you?')"
        echo "  [model]       For xtptd: model number (1-5) or name (gpt/llama/claude/o3/mistral)"
        echo "                For xtptc: model number (1-3) or name (llama/deepseek/llama70b)"
        echo ""
        echo "Example:"
        echo "  echo \"Vscode\" | xtptd \"what is {}, can it play music?\" claude"
        echo "  echo \"Python\" | xtptc \"explain {} in simple terms\" llama70b"
        echo ""
        return 0
    fi

    local cmd="$1"
    local template="$2"
    local model="$3"

    # If it's tptd/tptc and a model is specified, append it to the command
    if [[ ("$cmd" == "tptd" || "$cmd" == "tptc") && -n "$model" ]]; then
        while IFS= read -r input; do
            $cmd "$model" "${template//\{\}/$input}"
        done
    else
        while IFS= read -r input; do
            $cmd "${template//\{\}/$input}"
        done
    fi
}

# Create functions for different providers
xtptc() { _xtgpt "tptc" "$1" "$2" }
xtptd() { _xtgpt "tptd" "$1" "$2" }
xtptp() { _xtgpt "tptp" "$1" }

setCFenv() {
  # Retrieve credentials from KWallet
  local cf_api_key=$(kwalletcli -f "cloudFlare_api" -e "CF_WAI_API_Key" 2>/dev/null)
  local cf_account_id=$(kwalletcli -f "cloudFlare_api" -e "CF_WAI_ACC" 2>/dev/null)

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



########################################################
#####            Extra plugin/scripts              #####
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

# AI-powered Git commit message generator
gitcommsg() {
    local model="${1:-claude}"  # Default to claude if no model specified
    
    # Show help if requested
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: gitcommsg [model]"
        echo "Generate AI-powered commit messages from staged changes"
        echo ""
        echo "Available models (same as tptd):"
        echo "  gpt, 1     : gpt-4o-mini"
        echo "  llama, 2   : Llama-3.3-70B-Instruct-Turbo"
        echo "  claude, 3  : claude-3-haiku-20240307"
        echo "  o3, 4      : o3-mini"
        echo "  mistral, 5 : Mistral-Small-24B-Instruct-2501"
        echo ""
        echo "Examples:"
        echo "  gitcommsg            # uses claude (default)"
        echo "  gitcommsg llama      # uses llama model"
        echo "  gitcommsg 3          # uses claude model"
        echo "  gitcommsg mistral    # uses mistral model"
        echo ""
        echo "Output format:"
        echo "  feat: add user authentication"
        echo ""
        echo "  - implement JWT token handling"
        echo "  - add login/logout endpoints"
        echo ""
        echo "Default: claude"
        return 0
    fi

    local template='Analyze the following git diff and create a CONCISE but SPECIFIC commit message.
Format the message as:
type: <brief summary (max 50 chars)>

- [type] key change 1 (max 60 chars per line)
- [type] key change 2
- [type] key change N (include all significant changes)

Valid types:
- feat: New features
- add: Added new files/resources
- update: Updates to existing features
- remove: Removed files/features
- fix, bugfix: Bug fixes
- hotfix: Critical fixes
- docs: Documentation changes
- style: Code style/formatting
- ui: User interface changes
- refactor: Code restructuring
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
- data: Database/data structure changes
- config: Configuration changes
- api: API-related changes
- init: Initial commit/project setup

Rules:
1. Keep summary under 50 chars
2. One line per significant change
3. Be SPECIFIC - mention actual functions/files/features changed
4. Do not exclude important changes
5. Each specific change should have a relevant type in []
6. Avoid vague terms like "improve", "update", "fix" without context

Example:
refactor: Split user authentication into separate modules

- [refactor] Extract JWT validation to new auth/jwt.js module
- [feat] Add rate limiting to login endpoints (max 5 attempts)
- [fix] Prevent token refresh after password change
- [test] Add integration tests for auth workflows

Git diff: {}'

    git diff --staged | tptd "$model" "$template"
}
