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
    local diff_file=""

    # Parse arguments first
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                # Help message display
                echo "Usage: gitcommsg [model] [-m message] [-c] [-cc] [--tor] [-ml MODEL] [--g4f] [-pr PROVIDER] [--diff FILE]"
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
                echo "  gitcommsg --diff /tmp/changes.diff  # use external diff file"
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

    # Skip git repo check if we're using a diff file
    if [[ -z "$diff_file" ]]; then
        # Check if in a Git repository
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo "Error: Not a Git repository. Run this command from a Git project root."
            return 1
        fi

        # Check staged changes only when not using a diff file
        if ! git diff --cached --quiet; then
            : # Changes exist, continue
        else
            echo "Error: No staged changes found. Stage changes with 'git add' first."
            return 1
        fi
    fi

    # Validate context length if provided
    if [[ -n "$context" && ${#context} -gt 100 ]]; then
        echo "Error: Context message too long (max 100 characters)"
        return 1
    fi

    local context_prompt=""
    if [[ -n "$context" ]]; then
        context_prompt=$(cat <<EOF
ABSOLUTE PRIORITY INSTRUCTION: $context

This user-provided context OVERRIDES any conflicting inference from the diff.
You MUST:
1. Use $context as the primary basis for the commit type and summary
2. Only use the git diff to identify WHAT changed (files, functions, etc.)
3. Focus bullet points on changes that support or relate to $context
4. If the diff contains changes unrelated to $context, still prioritize 
   $context-related changes in your summary and bullets
5. Maintain the exact commit message format with proper types and detailed specifics

IMPORTANT: Each bullet point should use its own appropriate commit type tag [type] 
based on the nature of that specific change, NOT necessarily the same type as the main commit.
For example, a feat commit might include bullet points tagged as [feat], [fix], [refactor], etc.
depending on the nature of each specific change.

Example with context feat: login flow:
- Main commit type would be feat
- But bullet points might use different types like:
  [feat] Add new login page component
  [fix] Correct validation error in password field
  [style] Improve form layout for mobile devices
  [refactor] Separate authentication logic into its own module

EOF
)
    fi

    local template="$context_prompt   Analyze ONLY the exact changes in this git diff and create a precise, factual commit message.

FORMAT:
type: <concise summary> (max 50 chars)

- [type] <specific change 1> (filename:function/method/line)
- [type] <specific change 2> (filename:function/method/line)
- [type] <additional changes...>

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

IMPORTANT: If you receive partial analyses instead of a raw git diff, use ONLY that information to create your commit message. 
Do not ask for the original git diff - the partial analyses already contain all necessary information.

EXAMPLE:
Given a diff showing error handling added to auth.js and timeout changes in config.json:

fix: Improve authentication error handling

- [fix] Add try/catch in auth.js:authenticateUser()
- [fix] Handle network timeouts in auth.js:loginCallback()
- [config] Increase API timeout from 3000ms to 5000ms in config.json

Git diff or partial analyses to process:"

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
                else
                    # For initial chunking, we're processing raw git diff
                    chunk_template="Analyze this PARTIAL git diff and create a detailed technical summary with this EXACT format:

[FILES]: Comma-separated list of affected files with full paths
[CHANGES]: 
- Technical detail 1 (include function/method names, specific line changes)
- Technical detail 2 (be precise about what code was added/modified/removed)
- Additional technical details (include ALL significant changes in this chunk)
[IMPACT]: Brief technical description of what the changes accomplish

IMPORTANT: Be extremely specific and factual. Only describe code that actually changed.
Include exact function/method names, variable names, and other technical identifiers.
Focus on HOW the code changed, not speculation about WHY.

Diff chunk:"
                fi
                
                echo "\n🚧 Partial analysis:"
                local max_retries=3
                local retry_count=0
                local wait_seconds=10
                
                # Create a temporary file for the full prompt to avoid any stdout issues
                local prompt_file=$(mktemp)
                printf "%s\n\n" "$chunk_template" > "$prompt_file"
                cat "$chunk" >> "$prompt_file"
                
                while true; do
                    local tmpfile=$(mktemp)
                    local cmd_status=0

                    # Execute the appropriate command with or without tor
                    if $use_tor && ! $use_g4f; then
                        # G4F doesn't support tor directly
                        if [[ ${#ai_args[@]} -gt 0 ]]; then
                            $ai_cmd --tor "${ai_args[@]}" < "$prompt_file" | tee "$tmpfile"
                        else
                            $ai_cmd --tor "$model" < "$prompt_file" | tee "$tmpfile"
                        fi
                    else
                        # Normal execution with saved args
                        if [[ ${#ai_args[@]} -gt 0 ]]; then
                            $ai_cmd "${ai_args[@]}" < "$prompt_file" | tee "$tmpfile"
                        else
                            $ai_cmd "$model" < "$prompt_file" | tee "$tmpfile"
                        fi
                        cmd_status=${pipestatus[1]}
                    fi
                    
                    if [ $cmd_status -eq 0 ]; then
                        cat "$tmpfile" >> "$temp_dir/partials.txt"
                        # Clean up temporary files
                        rm -f "$prompt_file" "$tmpfile"
                        break
                    else
                        ((retry_count++))
                        if [ $retry_count -gt $max_retries ]; then
                            # Clean up temporary files
                            rm -f "$prompt_file" "$tmpfile"
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
                    # Clean up temporary file after each attempt
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
1. First line: \"type: brief summary\" (50 chars max)
2. One blank line
3. Bullet points with specific changes, each with appropriate [type] tag
4. ALWAYS reference specific files and functions in EACH bullet point

EXAMPLES OF GOOD BULLETS:
- [refactor] Update model function signature in src/models.py:process_input()
- [fix] Correct parameter validation in api/endpoints.js:validateUser()
- [docs] Add parameter descriptions for auth/login.py:authenticate()

STRICTLY follow this format with NO EXPLANATION or additional commentary.
DO NOT mention insufficient information or ask for the original diff.

Final commit message:"
            
            diff_input="$combine_template"
            
            # Recursive chunking for large messages
            if $recursive_chunk && (( recursion_depth < max_recursion )); then
                local msg_length=$(echo "$diff_input" | wc -l)
                local msg_threshold=50
                
                while (( msg_length > msg_threshold )) && (( recursion_depth < max_recursion )); do
                    echo "\n⚠️  Combined message too long (${msg_length} lines), re-chunking..."
                    ((recursion_depth++))
                    
                    # Create a special template for re-chunking that explicitly states we're working with partial analyses
                    local rechunk_template="IMPORTANT CONTEXT: You are analyzing SUMMARIES of git changes, not raw git diff.
                    
The following contains partial analyses of git changes that have already been processed.
Your task is to synthesize these analyses into a CONVENTIONAL COMMIT MESSAGE.

FORMAT:
type: <concise summary> (max 50 chars)

- [type] <specific change 1> (filename:function/method/line)
- [type] <specific change 2> (filename:function/method/line)
- [type] <additional changes...>

STRICTLY follow this format. Do NOT ask for raw git diff - work with the summaries provided.
DO NOT include any explanation or comments outside the commit message format.

Partial analyses to synthesize:"

                    echo "\n===== RECHUNKING LEVEL $recursion_depth ====="
                    
                    # For debugging, show a preview of what's being processed
                    echo "\n📄 Processing the following combined analyses:"
                    echo "$diff_input" | head -n 20
                    echo "... (total ${msg_length} lines)"
                    
                    # Process the long message as new input with the special template
                    echo "\n🔄 Generating new synthesis..."
                    local result=$(process_diff "$diff_input" "$rechunk_template")
                    
                    # Show the result
                    echo "\n📋 Rechunking result:"
                    echo "$result"
                    
                    # Update diff_input for next iteration
                    diff_input="$result"
                    msg_length=$(echo "$diff_input" | wc -l)
                    
                    echo "\n🔄 Recursion depth $recursion_depth - New length: ${msg_length} lines"
                done
            fi
        fi

        echo "\n🎉 Final commit message generation..."
        # Final command execution with tor support or g4f
        # Create a temporary file for the full prompt
        local final_prompt_file=$(mktemp)
        echo "$template" > "$final_prompt_file"
        echo "$diff_input" >> "$final_prompt_file"
        
        local result=""
        
        if $use_g4f; then
            if (( recursion_depth > 0 )); then
                result=$($ai_cmd -pr "$saved_provider" -ml "$saved_model" < "$final_prompt_file")
            else
                $ai_cmd -pr "$saved_provider" -ml "$saved_model" < "$final_prompt_file"
            fi
        elif $use_tor; then
            if $use_nazapi; then
                if (( recursion_depth > 0 )); then
                    result=$($ai_cmd --tor "${ai_args[@]}" < "$final_prompt_file")
                else
                    $ai_cmd --tor "${ai_args[@]}" < "$final_prompt_file"
                fi
            else
                if (( recursion_depth > 0 )); then
                    result=$($ai_cmd --tor "$model" < "$final_prompt_file")
                else
                    $ai_cmd --tor "$model" < "$final_prompt_file"
                fi
            fi
        else
            if $use_nazapi; then
                if (( recursion_depth > 0 )); then
                    result=$($ai_cmd "${ai_args[@]}" < "$final_prompt_file")
                else
                    $ai_cmd "${ai_args[@]}" < "$final_prompt_file"
                fi
            else
                if (( recursion_depth > 0 )); then
                    result=$($ai_cmd "$model" < "$final_prompt_file")
                else
                    $ai_cmd "$model" < "$final_prompt_file"
                fi
            fi
        fi
        
        # Clean up the final prompt file
        rm -f "$final_prompt_file"
        
        # If in recursion mode, return the result
        if (( recursion_depth > 0 )); then
            echo "$result"
        fi
    }

    # Capture diff and process
    local diff_content
    if [[ -n "$diff_file" ]]; then
        diff_content=$(cat "$diff_file")
        echo "Using diff from file: $diff_file"
    else
        diff_content=$(git diff --staged)
    fi
    
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