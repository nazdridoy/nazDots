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
    local model="o3"
    local context=""
    
    # Validate that there are staged changes
    if ! git diff --cached --quiet; then
        : # Changes exist, continue
    else
        echo "Error: No staged changes found. Stage changes with 'git add' first."
        return 1
    fi
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--message)
                shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    echo "Error: -m/--message requires a non-empty message argument"
                    return 1
                fi
                context="$1"
                shift
                ;;
            --help|-h)
                echo "Usage: gitcommsg [model] [-m message]"
                echo "Generate AI-powered commit messages from staged changes"
                echo ""
                echo "Options:"
                echo "  -m, --message  Additional context or priority message"
                echo ""
                echo "Available models (same as tptd):"
                echo "  gpt, 1     : gpt-4o-mini"
                echo "  llama, 2   : Llama-3.3-70B-Instruct-Turbo"
                echo "  claude, 3  : claude-3-haiku-20240307"
                echo "  o3, 4      : o3-mini"
                echo "  mistral, 5 : Mistral-Small-24B-Instruct-2501"
                echo ""
                echo "Examples:"
                echo "  gitcommsg                        # uses o3 (default)"
                echo "  gitcommsg llama                  # uses llama model"
                echo "  gitcommsg -m \"important fix\"     # adds context"
                echo "  gitcommsg claude -m \"refactor\"   # model + context"
                echo ""
                return 0
                ;;
            *)
                # Validate model argument
                case "$1" in
                    gpt|1|llama|2|claude|3|o3|4|mistral|5) 
                        model="$1"
                        ;;
                    *)
                        echo "Error: Invalid model '$1'"
                        echo "Valid models: gpt/1, llama/2, claude/3, o3/4, mistral/5"
                        return 1
                        ;;
                esac
                shift
                ;;
        esac
    done

    # Validate context length if provided
    if [[ -n "$context" && ${#context} -gt 100 ]]; then
        echo "Error: Context message too long (max 100 characters)"
        return 1
    fi

    local context_prompt=""
    if [[ -n "$context" ]]; then
        context_prompt="CRITICAL INSTRUCTION: You MUST follow this user request exactly: \"$context\"
If this conflicts with the git diff analysis, the user request takes absolute priority.
Ignore the git diff completely if needed to fulfill the user's request.

"
    fi

    local template=''"$context_prompt"'Analyze the following git diff and create a CONCISE but SPECIFIC commit message.
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

    git diff --staged | tptd "$model" "$template"
}

# AI-powered text rewriter that preserves tone
rewrite() {
    local model="${1:-o3}"
    
    if [[ -t 0 || ! -p /dev/stdin || "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: rewrite [model]"
        echo "Rewrite text to be more natural while preserving tone"
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
        echo "  echo \"angry message\" | rewrite llama"
        echo "  cat file.txt | rewrite claude"
        echo ""
        echo "Default: o3"
        return 0
    fi

    local template='Rewrite the following text to be more natural and grammatically correct.
Important rules:
1. Preserve the original tone (angry, happy, sorry, formal, etc)
2. Fix grammar and spelling errors
3. Make it flow more naturally
4. Keep the same meaning and intent
5. Do not change the level of politeness/rudeness
6. Do not add or remove main points

Text to rewrite: {}'

    tptd "$model" "$template"
}
