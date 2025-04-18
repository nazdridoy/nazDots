# AI-powered Git commit message generator
gitcommsg() {
    local model="sonar-pro"
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
    local diff_file=""
    local enable_logging=false
    local log_file="/tmp/gitcommsg_$(date +%Y%m%d_%H%M%S).log"

    # Internal logging function
    _log() {
        local level="$1"
        local message="$2"
        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        
        if $enable_logging; then
            echo "[$timestamp] [$level] $message" >> "$log_file"
        fi
    }

    # Log file contents
    _log_file_contents() {
        local level="$1"
        local description="$2"
        local filepath="$3"
        
        if $enable_logging && [[ -f "$filepath" ]]; then
            _log "$level" "===== BEGIN $description: $filepath ====="
            cat "$filepath" >> "$log_file"
            _log "$level" "===== END $description: $filepath ====="
        fi
    }

    # Parse arguments first
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                # Help message display
                echo "Usage: gitcommsg [model] [-m message] [-c] [-cc] [--tor] [-ml MODEL] [--g4f] [-pr PROVIDER] [--diff FILE] [--log]"
                echo "Generate AI-powered commit messages from staged changes or a diff file"
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
                echo "  --diff FILE    Use diff from specified file instead of staged changes"
                echo "  --log         Create detailed debug log file for troubleshooting"
                echo ""
                echo "Available models:"
                echo "  Online (default):"
                echo "    blackboxai-pro/1, blackboxai/2, claude-3-haiku/3, claude-3.5-sonnet/4,"
                echo "    claude-3.7-sonnet/5, deepseek-chat/6, deepseek-r1/7, deepseek-v3/8,"
                echo "    evil/9, glm-4/10, gpt-4/11, gpt-4o-mini/12, gpt-4o/13, hermes-3/14,"
                echo "    lfm-40b/15, llama-3.1-70b/16, llama-3.3-70b/17, llama-4-scout/18,"
                echo "    meta-ai/19, o3-mini/20, r1-1776/21, sonar-pro/22, sonar-reasoning-pro/23"
                echo "  nazOllama API (-ml):"
                echo "    Any model supported by tptn (e.g. deepseek-r1:14b)"
                echo "  gpt4free (--g4f):"
                echo "    Interactive selection or specify with -pr and -ml"
                echo ""
                echo "Examples:"
                echo "  gitcommsg                        # uses sonar-pro (default)"
                echo "  gitcommsg gpt-4o                  # uses gpt-4o model"
                echo "  gitcommsg -m \"important fix\"     # adds context"
                echo "  gitcommsg claude-3.7-sonnet -m \"refactor\" # model + context"
                echo "  gitcommsg -ml deepseek-r1:14b    # uses nazOllama API with specified model"
                echo "  gitcommsg --tor -ml llama3.2:latest -m \"security fix\""
                echo "  gitcommsg --g4f                  # uses interactive gpt4free selection"
                echo "  gitcommsg --g4f -pr DDG -ml o3-mini # uses specific gpt4free provider/model"
                echo "  gitcommsg --diff /tmp/changes.diff  # use external diff file"
                echo "  gitcommsg --log                  # create detailed debug log"
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
            --log)
                enable_logging=true
                echo "Logging enabled. Log file: $log_file"
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
            --diff)
                shift
                if [[ -z "$1" || "$1" =~ ^- ]]; then
                    echo "Error: --diff requires a file path argument"
                    return 1
                fi
                if [[ ! -f "$1" ]]; then
                    echo "Error: Diff file '$1' not found"
                    return 1
                fi
                diff_file="$1"
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
                        blackboxai-pro|1|blackboxai|2|claude-3-haiku|3|claude-3.5-sonnet|4|claude-3.7-sonnet|5|deepseek-chat|6|deepseek-r1|7|deepseek-v3|8|evil|9|glm-4|10|gpt-4|11|gpt-4o-mini|12|gpt-4o|13|hermes-3|14|lfm-40b|15|llama-3.1-70b|16|llama-3.3-70b|17|llama-4-scout|18|meta-ai|19|o3-mini|20|r1-1776|21|sonar-pro|22|sonar-reasoning-pro|23) 
                            model="$1"
                            shift
                            ;;
                        *)
                            echo "Error: Invalid model '$1'"
                            echo "Valid models: blackboxai-pro/1, blackboxai/2, claude-3-haiku/3, claude-3.5-sonnet/4,"
                            echo "claude-3.7-sonnet/5, deepseek-chat/6, deepseek-r1/7, deepseek-v3/8,"
                            echo "evil/9, glm-4/10, gpt-4/11, gpt-4o-mini/12, gpt-4o/13, hermes-3/14,"
                            echo "lfm-40b/15, llama-3.1-70b/16, llama-3.3-70b/17, llama-4-scout/18,"
                            echo "meta-ai/19, o3-mini/20, r1-1776/21, sonar-pro/22, sonar-reasoning-pro/23"
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
            _log "ERROR" "g4f validation failed: Both provider and model must be specified"
            return 1
        fi
    fi

    # Skip git repo check if we're using a diff file
    if [[ -z "$diff_file" ]]; then
        # Check if in a Git repository
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo "Error: Not a Git repository. Run this command from a Git project root."
            _log "ERROR" "Not in a Git repository"
            return 1
        fi

        # Check staged changes only when not using a diff file
        if ! git diff --cached --quiet; then
            : # Changes exist, continue
            _log "INFO" "Found staged changes for commit"
        else
            echo "Error: No staged changes found. Stage changes with 'git add' first."
            _log "ERROR" "No staged changes found"
            return 1
        fi
    fi

    # Validate context length if provided
    if [[ -n "$context" && ${#context} -gt 100 ]]; then
        echo "Error: Context message too long (max 100 characters)"
        _log "ERROR" "Context message too long: ${#context} characters (max 100)"
        return 1
    fi

    local context_prompt=""
    if [[ -n "$context" ]]; then
        _log "INFO" "Using context: $context"
        context_prompt=$(cat <<EOF
⚠️ CRITICAL INSTRUCTION - HIGHEST PRIORITY - NO EXCEPTIONS ⚠️

Context provided: "$context"

█ MANDATORY FILE TYPE FILTERING █

IF "$context" MENTIONS A FILE TYPE OR TECHNOLOGY:
* YOU MUST INCLUDE ONLY changes to that specific file type
* YOU MUST EXCLUDE ALL other files completely from your output
* THIS IS A STRICT FILTER - NO EXCEPTIONS ALLOWED

FILE TYPE MAPPING:
- Web: HTML (.html), CSS (.css), JavaScript (.js)
- Scripts: Shell (.sh), Python (.py), Ruby (.rb), PowerShell (.ps1), Batch (.bat), JavaScript (.js)
- Languages: C/C++ (.c/.cpp), Python (.py), Go (.go), Rust (.rs), Java (.java)

SPECIFIC TERM HANDLING:
- "html" → ONLY include .html files, EXCLUDE ALL others
- "css" → ONLY include .css files, EXCLUDE ALL others
- "script" → ONLY include script files (.js/.sh/.py/.rb/.ps1/.bat), EXCLUDE ALL others
- "javascript" → ONLY include .js files, EXCLUDE ALL others
- "python" → ONLY include .py files, EXCLUDE ALL others
- "auth handler" → ONLY include files related to authentication handlers
- "ui" → ONLY include files related to user interfaces
- "api" → ONLY include files related to APIs
- "config" → ONLY include files related to configurations
- "middleware" → ONLY include files related to middleware
- "handler" → ONLY include files related to handlers

FORBIDDEN CONTENT EXAMPLES:
- For "updated html" → Your response MUST NOT mention: script.js, styles.css
- For "updated script" → Your response MUST NOT mention: index.html, styles.css
- For "fixed css" → Your response MUST NOT mention: index.html, script.js
- For "refactored auth handler" → Your response MUST NOT mention: api.py, api_handler.py, api_handler.js, etc.

FILES OUTSIDE YOUR FILTER MUST BE COMPLETELY REMOVED FROM RESPONSE.

█ COMMIT TYPE DIRECTIVE - HIGHEST PRIORITY █

⚠️ CRITICAL - COMMIT TYPE HANDLING ⚠️

1. EXPLICIT TYPE FORMAT (HIGHEST PRIORITY):
   If context contains "type:X" format:
   - EXACTLY use "X:" as the commit type prefix
   - Example: "type:init" → MUST use "init:"
   - Example: "type:release" → MUST use "release:"
   - Example: "type:refactor" → MUST use "refactor:"
   - NO EXCEPTIONS - TYPE MUST BE USED EXACTLY AS SPECIFIED

2. SINGLE WORD TYPE:
   If context is a single word matching a commit type:
   - Use that word directly as the type
   - Example: "init" → "init:"
   - Example: "feat" → "feat:"
   - Example: "fix" → "fix:"

⚠️ STRICT ENFORCEMENT RULES ⚠️
1. When "type:X" is present, that type MUST be used - NO EXCEPTIONS
2. The commit type MUST appear in the first line of the output
3. The commit type MUST be followed by a colon and space (": ")
4. DO NOT change or override the specified commit type
5. DO NOT generate a different type based on content analysis
6. The commit type takes precedence over all other directives

█ COMMAND MODE █

IF "$context" IS A DIRECT COMMAND:
- DO EXACTLY WHAT IT SAYS, ignoring diff if instructed
- If told to "ignore X", COMPLETELY EXCLUDE X
- If told to "just say X", OUTPUT ONLY X

█ FOCUS DIRECTIVE █

IF "$context" CONTAINS "focus on", "only mention", etc.:
- ONLY include changes matching the specified focus
- COMPLETELY EXCLUDE everything else
- For "focus only on css" → Include ONLY CSS-related changes

█ EXCLUSION DIRECTIVE █

IF "$context" SAYS "ignore", "don't include", "exclude":
- COMPLETELY REMOVE any mention of the specified exclusion
- For "ignore formatting" → Remove ALL formatting changes

█ OUTPUT FORMATTING █

- Start directly with commit type and summary
- NEVER include phrases like "Based on the directive" or explanations
- Output ONLY the commit message itself

THIS DIRECTIVE OVERRIDES ALL OTHER INSTRUCTIONS
EOF
)
        _log "DEBUG" "Generated context_prompt with $(echo "$context_prompt" | wc -l) lines"
    fi

    # Create initial template
    local template="$context_prompt   Analyze ONLY the exact changes in this git diff and create a precise, factual commit message.

FORMAT:
type[(scope)]: <concise summary> (max 50 chars)

- [type] <specific change 1> (filename:function/method/line)
- [type] <specific change 2> (filename:function/method/line)
- [type] <additional changes...>

RULES FOR FILENAMES:
1. Use short relative paths when possible
2. For multiple changes to the same file, consider grouping them
3. Abbreviate long paths when they're repeated (e.g., 'commit.zsh' instead of full path)
4. Avoid breaking filenames across lines
5. Only include function names when they add clarity

COMMIT TYPES:
- feat: New user-facing features
- fix: Bug fixes or error corrections
- refactor: Code restructuring (no behavior change)
- style: Formatting/whitespace changes only
- docs: Documentation only
- test: Test-related changes
- perf: Performance improvements
- build: Build system changes
- ci: CI/CD pipeline changes
- chore: Routine maintenance tasks
- revert: Reverting previous changes
- add: New files without user-facing features
- remove: Removing files/code
- update: Changes to existing functionality
- security: Security-related changes
- config: Configuration changes
- ui: User interface changes
- api: API-related changes

RULES:
1. BE 100% FACTUAL - Mention ONLY code explicitly shown in the diff
2. NEVER invent or assume changes not directly visible in the code
3. EVERY bullet point MUST reference specific files/functions/lines
4. Include ALL significant changes (do not skip any important modifications)
5. If unsure about a change's purpose, describe WHAT changed, not WHY
6. Keep summary line under 50 characters (mandatory)
7. Use appropriate type tags for each change (main summary and each bullet)
8. ONLY describe code that was actually changed
9. Focus on technical specifics, avoid general statements
10. Include proper technical details (method names, component identifiers, etc.)
11. When all changes are to the same file, mention it once in the summary

IMPORTANT: If you receive partial analyses instead of a raw git diff, use ONLY that information to create your commit message. 
Do not ask for the original git diff - the partial analyses already contain all necessary information.

EXAMPLE:
Given a diff showing error handling added to auth.js and timeout changes in config.json:

fix(auth): Improve authentication error handling

- [fix] Add try/catch in auth.js:authenticateUser()
- [fix] Handle network timeouts in auth.js:loginCallback()
- [config] Increase API timeout from 3000ms to 5000ms in config.json

SCOPE RULES:
1. Only include scope when you are 100% confident about the affected area
2. Scope should be a short, lowercase identifier (e.g., auth, api, ui, docs)
3. If scope is unclear or changes affect multiple areas, omit the scope
4. Common scopes: auth, api, ui, docs, test, build, deps, config
5. Scope should match the primary area of change

Git diff or partial analyses to process:"

    if $enable_logging; then
        local tmp_initial_template=$(mktemp)
        echo "$template" > "$tmp_initial_template"
        _log_file_contents "DEBUG" "INITIAL_TEMPLATE" "$tmp_initial_template"
        rm -f "$tmp_initial_template"
    fi

    local process_diff() {
        local diff_input="$1"
        local template="$2"
        local recursion_depth=0
        local max_recursion=3
        local ai_cmd="tptb"
        local ai_args=()

        _log "INFO" "Starting process_diff function with recursion_depth=$recursion_depth"
        _log "DEBUG" "Template size: $(echo "$template" | wc -l) lines"
        _log "DEBUG" "Diff input size: $(echo "$diff_input" | wc -l) lines"

        # Determine which AI command to use
        if $use_g4f; then
            ai_cmd="tptg"
            _log "INFO" "Using g4f provider via tptg"
            # If provider and model are specified, use them
            if [[ -n "$g4f_provider" && -n "$g4f_model" ]]; then
                saved_provider="$g4f_provider"
                saved_model="$g4f_model"
                ai_args=("-pr" "$g4f_provider" "-ml" "$g4f_model")
                _log "INFO" "Using specified g4f provider '$g4f_provider' and model '$g4f_model'"
            elif [[ -n "$saved_provider" && -n "$saved_model" ]]; then
                # Reuse previously selected provider and model
                ai_args=("-pr" "$saved_provider" "-ml" "$saved_model")
                _log "INFO" "Reusing previously selected provider '$saved_provider' and model '$saved_model'"
            elif [[ -n "$G4F_SELECTED_PROVIDER" && -n "$G4F_SELECTED_MODEL" ]]; then
                # Use previously exported variables from tptg
                saved_provider="$G4F_SELECTED_PROVIDER"
                saved_model="$G4F_SELECTED_MODEL"
                ai_args=("-pr" "$saved_provider" "-ml" "$saved_model")
                echo "Using previously selected provider '$saved_provider' and model '$saved_model'"
                _log "INFO" "Using previously exported provider '$saved_provider' and model '$saved_model'"
            fi
            # Otherwise, interactive selection will be used
        elif $use_nazapi; then
            ai_cmd="tptn"
            ai_args=("-ml" "$nazapi_model")
            _log "INFO" "Using nazOllama API with model '$nazapi_model'"
        else
            _log "INFO" "Using default command $ai_cmd with model $model"
        fi
        
        # For interactive g4f, do a quick one-time selection via tptg
        if [[ "$ai_cmd" == "tptg" && ${#ai_args[@]} -eq 0 ]]; then
            echo "Running interactive provider/model selection via tptg..."
            _log "INFO" "Running interactive provider/model selection via tptg"
            
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
                _log "INFO" "Interactively selected provider '$saved_provider' and model '$saved_model'"
            else
                _log "ERROR" "Provider and model selection failed"
                echo "Error: Provider and model selection failed"
                return 1
            fi
        fi
        
        if $chunk_mode; then
            echo "Processing diff in chunks (${chunk_size} lines)..."
            _log "INFO" "Processing diff in chunks (${chunk_size} lines)"
            
            # Create temp directory
            local temp_dir=$(mktemp -d)
            _log "DEBUG" "Created temporary directory: $temp_dir"
            trap "rm -rf $temp_dir" EXIT
            
            # Split diff into chunks
            echo "$diff_input" | split -l $chunk_size - "$temp_dir/chunk_"
            
            local chunk_count=$(ls "$temp_dir" | wc -l)
            echo "Found $chunk_count chunks to process"
            _log "INFO" "Found $chunk_count chunks to process"
            
            # Process each chunk
            local i=1
            for chunk in "$temp_dir"/chunk_*; do
                echo "\n=== CHUNK $i/$chunk_count ==="
                echo "Raw diff lines: $(wc -l < "$chunk")"
                _log "INFO" "Processing chunk $i/$chunk_count with $(wc -l < "$chunk") lines"
                
                # Create the chunk template without printing it
                local chunk_template=""
                
                # Check if we're in a re-chunking operation
                if (( recursion_depth > 0 )); then
                    # For re-chunking, we're processing partial analyses, not git diff
                    chunk_template="IMPORTANT: You are analyzing SUMMARIES of git changes, not raw git diff.

You are in a re-chunking process where the input is already summarized changes.
Create a TERSE summary of these summaries focusing ONLY ON TECHNICAL CHANGES:

[CHANGES]:
- Technical change 1 (specific file and function)
- Technical change 2 (specific file and function)
- Additional relevant changes

DO NOT ask for raw git diff. These summaries are all you need to work with.
Keep your response FACTUAL and SPECIFIC to what's in the summaries.

Section to summarize:"
                    
                    # For re-chunking, show different information
                    echo "Re-chunking summary at level $recursion_depth"
                    _log "INFO" "Using re-chunking template at depth $recursion_depth"
                else
                    # For initial chunking, we're processing raw git diff
                    chunk_template="Analyze this PARTIAL git diff and create a detailed technical summary with this EXACT format:

[FILES]: Comma-separated list of affected files with full paths

[CHANGES]: 
- Technical detail 1 (include specific function/method names and line numbers)
- Technical detail 2 (be precise about exactly what code was added/modified/removed)
- Additional technical details (include ALL significant changes in this chunk)

[IMPACT]: Brief technical description of what the changes accomplish

CRITICALLY IMPORTANT: Be extremely specific with technical details.
ALWAYS identify exact function names, method names, class names, and line numbers where possible.
Use format 'filename:function_name()' or 'filename:line_number' when referencing code locations.
Be precise and factual - only describe code that actually changed.

Diff chunk:"
                    _log "INFO" "Using initial chunking template"
                fi
                
                if $enable_logging; then
                    local tmp_chunk_template=$(mktemp)
                    echo "$chunk_template" > "$tmp_chunk_template"
                    _log_file_contents "DEBUG" "CHUNK_TEMPLATE_DEPTH_${recursion_depth}" "$tmp_chunk_template"
                    rm -f "$tmp_chunk_template"
                fi
                
                echo "\n🚧 Partial analysis:"
                local max_retries=3
                local retry_count=0
                local wait_seconds=10
                
                # Create a temporary file for the full prompt to avoid any stdout issues
                local prompt_file=$(mktemp)
                printf "%s\n\n" "$chunk_template" > "$prompt_file"
                cat "$chunk" >> "$prompt_file"
                _log "DEBUG" "Created prompt file: $prompt_file with $(wc -l < "$prompt_file") lines"
                _log_file_contents "DEBUG" "PROMPT_FILE" "$prompt_file"
                
                while true; do
                    local tmpfile=$(mktemp)
                    local cmd_status=0
                    _log "DEBUG" "Created output file: $tmpfile"

                    # Execute the appropriate command with or without tor
                    if $use_tor && ! $use_g4f; then
                        # G4F doesn't support tor directly
                        _log "INFO" "Executing with Tor: attempt $(($retry_count + 1))/$max_retries"
                        if [[ ${#ai_args[@]} -gt 0 ]]; then
                            $ai_cmd --tor "${ai_args[@]}" "$(cat "$prompt_file")" | tee "$tmpfile"
                        else
                            $ai_cmd --tor "$model" "$(cat "$prompt_file")" | tee "$tmpfile"
                        fi
                    else
                        # Normal execution with saved args
                        _log "INFO" "Executing without Tor: attempt $(($retry_count + 1))/$max_retries"
                        if [[ ${#ai_args[@]} -gt 0 ]]; then
                            # All tpt* commands expect arguments, not stdin
                            $ai_cmd "${ai_args[@]}" "$(cat "$prompt_file")" | tee "$tmpfile"
                        else
                            $ai_cmd "$model" "$(cat "$prompt_file")" | tee "$tmpfile"
                        fi
                        cmd_status=${pipestatus[1]}
                    fi
                    
                    if [ $cmd_status -eq 0 ]; then
                        _log "INFO" "Command executed successfully"
                        cat "$tmpfile" >> "$temp_dir/partials.txt"
                        _log_file_contents "DEBUG" "OUTPUT_FILE" "$tmpfile"
                        # Clean up temporary files
                        rm -f "$prompt_file" "$tmpfile"
                        break
                    else
                        ((retry_count++))
                        _log "WARNING" "Command failed with status $cmd_status (attempt $retry_count/$max_retries)"
                        if [ $retry_count -gt $max_retries ]; then
                            # Clean up temporary files
                            rm -f "$prompt_file" "$tmpfile"
                            _log "ERROR" "Failed after $max_retries retries. Aborting."
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
                        _log "INFO" "Retrying with backoff: next wait time = $wait_seconds seconds"
                    fi
                    # Clean up temporary file after each attempt
                    rm -f "$tmpfile"
                done
                
                ((i++))
                
                # Rate limit protection
                if ((i < chunk_count)); then
                    echo -n "⏳ Pausing 10s "
                    _log "INFO" "Pausing 10s between chunks for rate limit protection"
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
            _log "INFO" "Collected $(grep -c "^" "$temp_dir/partials.txt") lines of partial analyses"
            cat "$temp_dir/partials.txt"
            
            if $enable_logging; then
                _log_file_contents "DEBUG" "COLLECTED_PARTIALS" "$temp_dir/partials.txt"
            fi
            
            # Combine partial results
            echo "\n🔨 Combining partial analyses..."
            _log "INFO" "Starting combination of partial analyses"
            
            # Read the partial analyses
            local partial_analyses=$(cat "$temp_dir/partials.txt")
            
            # Create combine template as a regular string
            local combine_template="===CRITICAL INSTRUCTION===
You are working with ANALYZED SUMMARIES of git changes, NOT raw git diff.
The raw git diff has ALREADY been processed into these summaries.
DO NOT ask for or expect to see the original git diff.

TASK: Synthesize these partial analyses into a complete conventional commit message:

$partial_analyses

Create a CONVENTIONAL COMMIT MESSAGE with:
1. First line: \"type[(scope)]: brief summary\" (50 chars max)
   - Include scope ONLY if you are 100% confident about the affected area
   - Omit scope if changes affect multiple areas or scope is unclear
2. ⚠️ ONE BLANK LINE IS MANDATORY - NEVER SKIP THIS STEP ⚠️
   - This blank line MUST be present in EVERY commit message
   - The blank line separates the summary from the detailed changes
   - Without this blank line, the commit message format is invalid
3. Bullet points with specific changes, each with appropriate [type] tag
4. Reference files in EACH bullet point with function names or line numbers

FILENAME & FUNCTION HANDLING RULES:
- Include SPECIFIC function names, method names, or line numbers when available
- Format as filename:function() or filename:line_number
- Use short relative paths for files (e.g., 'Provider/Chatai.py' instead of 'g4f/Provider/Chatai.py')
- Group related changes to the same file when appropriate
- Avoid breaking long filenames across lines

EXAMPLES OF GOOD COMMITS:
fix(auth): Improve authentication error handling

- [fix] Add try/catch in auth.js:authenticateUser()
- [fix] Handle network timeouts in auth.js:loginCallback()

feat: Add new data processing pipeline

- [feat] Implement data transformation pipeline
- [test] Add unit tests for pipeline components

refactor(ui): Restructure component hierarchy

- [refactor] Extract common UI components
- [style] Update component styling

docs: Update API documentation

- [docs] Add authentication endpoints documentation
- [docs] Update request/response examples

test: Add integration tests for payment flow

- [test] Add payment gateway integration tests
- [test] Add transaction validation tests

EXAMPLES OF GOOD BULLETS:
- [refactor] Update model function signature in models.py:process_input()
- [fix] Correct parameter validation in api/endpoints.js:validateUser()
- [docs] Add parameter descriptions for login.py:authenticate()
- [feat] Add new provider implementation (Provider/Chatai.py)

STRICTLY follow this format with NO EXPLANATION or additional commentary.
DO NOT mention insufficient information or ask for the original diff.

Final commit message:"
            
            if $enable_logging; then
                local tmp_combine=$(mktemp)
                echo "$combine_template" > "$tmp_combine"
                _log_file_contents "DEBUG" "COMBINE_TEMPLATE" "$tmp_combine"
                rm -f "$tmp_combine"
            fi
            
            diff_input="$combine_template"
            _log "DEBUG" "Created combine template with $(echo "$combine_template" | wc -l) lines"
            
            # Recursive chunking for large messages
            if $recursive_chunk && (( recursion_depth < max_recursion )); then
                local msg_length=$(echo "$diff_input" | wc -l)
                local msg_threshold=50
                
                while (( msg_length > msg_threshold )) && (( recursion_depth < max_recursion )); do
                    echo "\n⚠️  Combined message too long (${msg_length} lines), re-chunking..."
                    _log "INFO" "Combined message too long (${msg_length} lines), re-chunking"
                    ((recursion_depth++))
                    
                    # Create a special template for re-chunking that explicitly states we're working with partial analyses
                    local rechunk_template="IMPORTANT CONTEXT: You are analyzing SUMMARIES of git changes, not raw git diff.
                    
The following contains partial analyses of git changes that have already been processed.
Your task is to synthesize these analyses into a CONVENTIONAL COMMIT MESSAGE.

FORMAT:
type[(scope)]: <concise summary> (max 50 chars)

- [type] <specific change 1> (filename:function/method/line)
- [type] <specific change 2> (filename:function/method/line)
- [type] <additional changes...>

FUNCTION & LINE REFERENCE RULES:
- PRESERVE specific function names, method names, or line numbers from the analyses
- Use format: filename:function_name() or filename:line_number
- Keep detailed technical references intact
- Use short paths for filenames when appropriate
- Group related changes when they affect the same file

STRICTLY follow this format. Do NOT ask for raw git diff - work with the summaries provided.
DO NOT include any explanation or comments outside the commit message format.

Partial analyses to synthesize:"

                    if $enable_logging; then
                        local tmp_rechunk=$(mktemp)
                        echo "$rechunk_template" > "$tmp_rechunk"
                        _log_file_contents "DEBUG" "RECHUNK_TEMPLATE" "$tmp_rechunk"
                        rm -f "$tmp_rechunk"
                    fi

                    echo "\n===== RECHUNKING LEVEL $recursion_depth ====="
                    _log "INFO" "Starting re-chunking at depth $recursion_depth"
                    
                    # For debugging, show a preview of what's being processed
                    echo "\n📄 Processing combined analyses (${msg_length} lines)"
                    # Don't show the actual content to avoid crowded output
                    _log "DEBUG" "Processing combined analyses with $msg_length lines"
                    local tmp_analyses=$(mktemp)
                    echo "$diff_input" > "$tmp_analyses"
                    _log_file_contents "DEBUG" "COMBINED_ANALYSES" "$tmp_analyses"
                    rm -f "$tmp_analyses"
                    
                    # Process the long message as new input with the special template
                    echo "\n🔄 Generating new synthesis..."
                    _log "INFO" "Generating new synthesis at depth $recursion_depth"
                    
                    # FIX: Directly process without recursion for rechunking
                    local tempfile=$(mktemp)
                    local cmd_status=0
                    _log "DEBUG" "Created temporary file for rechunking result: $tempfile"
                    
                    # Prepare full prompt in a file
                    local rechunk_prompt_file=$(mktemp)
                    echo "$rechunk_template" > "$rechunk_prompt_file"
                    echo "$diff_input" >> "$rechunk_prompt_file"
                    _log "DEBUG" "Created rechunk prompt file with $(wc -l < "$rechunk_prompt_file") lines"
                    _log_file_contents "DEBUG" "RECHUNK_PROMPT_FILE" "$rechunk_prompt_file"
                    
                    # Execute the command directly without recursion
                    if $use_g4f; then
                        _log "INFO" "Executing rechunk with g4f provider"
                        $ai_cmd -pr "$saved_provider" -ml "$saved_model" "$(cat "$rechunk_prompt_file")" > "$tempfile"
                        cmd_status=$?
                    elif $use_tor; then
                        if $use_nazapi; then
                            _log "INFO" "Executing rechunk with nazapi over tor"
                            $ai_cmd --tor "${ai_args[@]}" "$(cat "$rechunk_prompt_file")" > "$tempfile"
                            cmd_status=$?
                        else
                            _log "INFO" "Executing rechunk with model over tor"
                            $ai_cmd --tor "$model" "$(cat "$rechunk_prompt_file")" > "$tempfile"
                            cmd_status=$?
                        fi
                    else
                        if $use_nazapi; then
                            _log "INFO" "Executing rechunk with nazapi"
                            $ai_cmd "${ai_args[@]}" "$(cat "$rechunk_prompt_file")" > "$tempfile"
                            cmd_status=$?
                        else
                            _log "INFO" "Executing rechunk with model"
                            $ai_cmd "$model" "$(cat "$rechunk_prompt_file")" > "$tempfile"
                            cmd_status=$?
                        fi
                    fi
                    
                    rm -f "$rechunk_prompt_file"
                    
                    if [ $cmd_status -ne 0 ]; then
                        _log "ERROR" "Rechunking failed with status $cmd_status"
                        echo "❌ Rechunking failed. Aborting."
                        rm -f "$tempfile"
                        return 1
                    fi
                    
                    # Show the result
                    echo "\n📋 Rechunking result:"
                    cat "$tempfile"
                    
                    # Update diff_input with the new result
                    diff_input=$(cat "$tempfile")
                    rm -f "$tempfile"
                    
                    _log "DEBUG" "Rechunking result: $(echo "$diff_input" | wc -l) lines"
                    local tmp_result=$(mktemp)
                    echo "$diff_input" > "$tmp_result"
                    _log_file_contents "DEBUG" "RECHUNKING_RESULT" "$tmp_result"
                    rm -f "$tmp_result"
                    
                    msg_length=$(echo "$diff_input" | wc -l)
                    
                    echo "\n🔄 Recursion depth $recursion_depth - New length: ${msg_length} lines"
                    _log "INFO" "Recursion depth $recursion_depth - New length: ${msg_length} lines"
                    
                    # Add a safeguard against empty results which could cause infinite loops
                    if [ -z "$diff_input" ]; then
                        _log "ERROR" "Rechunking produced empty result, breaking loop"
                        echo "⚠️ Rechunking produced empty result, continuing with final processing..."
                        diff_input="ERROR: Rechunking produced empty result. Please try with smaller diff or without recursive chunking."
                        break
                    fi
                done
            fi
        fi

        echo "\n🎉 Final commit message generation..."
        _log "INFO" "Starting final commit message generation"
        # Final command execution with tor support or g4f
        # Create a temporary file for the full prompt
        local final_prompt_file=$(mktemp)
        echo "$template" > "$final_prompt_file"
        echo "$diff_input" >> "$final_prompt_file"
        _log "DEBUG" "Created final prompt file with $(wc -l < "$final_prompt_file") lines"
        _log_file_contents "DEBUG" "FINAL_PROMPT_FILE" "$final_prompt_file"
        
        local result=""
        
        if $use_g4f; then
            if (( recursion_depth > 0 )); then
                _log "INFO" "Executing final g4f command with recursion"
                result=$($ai_cmd -pr "$saved_provider" -ml "$saved_model" "$(cat "$final_prompt_file")")
            else
                _log "INFO" "Executing final g4f command"
                # For tptg, we need to pass the content as an argument rather than stdin
                $ai_cmd -pr "$saved_provider" -ml "$saved_model" "$(cat "$final_prompt_file")"
            fi
        elif $use_tor; then
            if $use_nazapi; then
                if (( recursion_depth > 0 )); then
                    _log "INFO" "Executing final nazapi command with tor and recursion"
                    result=$($ai_cmd --tor "${ai_args[@]}" "$(cat "$final_prompt_file")")
                else
                    _log "INFO" "Executing final nazapi command with tor"
                    $ai_cmd --tor "${ai_args[@]}" "$(cat "$final_prompt_file")"
                fi
            else
                if (( recursion_depth > 0 )); then
                    _log "INFO" "Executing final command with tor and recursion"
                    result=$($ai_cmd --tor "$model" "$(cat "$final_prompt_file")")
                else
                    _log "INFO" "Executing final command with tor"
                    $ai_cmd --tor "$model" "$(cat "$final_prompt_file")"
                fi
            fi
        else
            if $use_nazapi; then
                if (( recursion_depth > 0 )); then
                    _log "INFO" "Executing final nazapi command with recursion"
                    result=$($ai_cmd "${ai_args[@]}" "$(cat "$final_prompt_file")")
                else
                    _log "INFO" "Executing final nazapi command"
                    $ai_cmd "${ai_args[@]}" "$(cat "$final_prompt_file")"
                fi
            else
                if (( recursion_depth > 0 )); then
                    _log "INFO" "Executing final command with recursion"
                    result=$($ai_cmd "$model" "$(cat "$final_prompt_file")")
                else
                    _log "INFO" "Executing final command"
                    $ai_cmd "$model" "$(cat "$final_prompt_file")"
                fi
            fi
        fi
        
        # Clean up the final prompt file
        rm -f "$final_prompt_file"
        _log "DEBUG" "Removed final prompt file"
        
        # If in recursion mode, return the result
        if (( recursion_depth > 0 )); then
            _log "INFO" "Returning result from recursion depth $recursion_depth"
            echo "$result"
        else
            # Log the final result when not in recursion mode
            if $enable_logging && [[ -n "$result" ]]; then
                local final_result_file=$(mktemp)
                echo "$result" > "$final_result_file"
                _log_file_contents "INFO" "FINAL_RESULT" "$final_result_file"
                rm -f "$final_result_file"
            fi
        fi
    }

    # Capture diff and process
    local diff_content
    if [[ -n "$diff_file" ]]; then
        diff_content=$(cat "$diff_file")
        echo "Using diff from file: $diff_file"
        _log "INFO" "Using diff from file: $diff_file ($(echo "$diff_content" | wc -l) lines)"
        if $enable_logging; then
            local tmp_diff=$(mktemp)
            echo "$diff_content" > "$tmp_diff"
            _log_file_contents "DEBUG" "INITIAL_DIFF" "$tmp_diff"
            rm -f "$tmp_diff"
        fi
    else
        diff_content=$(git diff --staged)
        _log "INFO" "Using staged changes ($(echo "$diff_content" | wc -l) lines)"
        if $enable_logging; then
            local tmp_diff=$(mktemp)
            echo "$diff_content" > "$tmp_diff"
            _log_file_contents "DEBUG" "INITIAL_DIFF" "$tmp_diff"
            rm -f "$tmp_diff"
        fi
    fi
    
    _log "INFO" "Starting commit message generation with options: model=$model, chunk_mode=$chunk_mode, recursive_chunk=$recursive_chunk, use_tor=$use_tor, use_nazapi=$use_nazapi, use_g4f=$use_g4f"
    
    if ! process_diff "$diff_content" "$template"; then
        # Clean up environment variables even on failure
        unset G4F_SELECTED_PROVIDER
        unset G4F_SELECTED_MODEL
        _log "ERROR" "process_diff failed"
        return 1
    fi
    
    # Clean up environment variables when done
    unset G4F_SELECTED_PROVIDER
    unset G4F_SELECTED_MODEL
    _log "INFO" "Commit message generation completed successfully"
}