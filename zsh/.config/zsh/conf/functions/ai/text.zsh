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

    # Capture stdin input
    local input_text
    input_text=$(cat)

    local template
    template=$(cat << 'TEMPLATE'
Rewrite the following text to sound natural while maintaining its original character.

RULES:
1. Preserve: original tone, intent, meaning, politeness level, rudeness level, technical terms, formatting
2. Improve: grammar, spelling, flow, clarity, readability
3. Convert passive voice to active when appropriate
4. Break up sentences longer than 25 words
5. Replace unnecessarily complex language with simpler alternatives
6. Remove redundancies and filler words

FORMAT PRESERVATION:
- Keep code blocks (```) exactly as they appear
- Maintain paragraph breaks and list structures
- Preserve URLs, email addresses, file paths, and variables like {placeholder}
- Respect original markdown formatting

WHAT TO AVOID:
- Don't add new information or remove key points
- Don't change the formality level
- Don't insert your own commentary
- Don't explain what you changed

EXAMPLES:
ORIGINAL: "The implementation of the feature, which was delayed due to unforeseen technical complications, is now scheduled for next week's release."
BETTER: "We delayed the feature implementation due to unforeseen technical complications. It's now scheduled for next week's release."

ORIGINAL: "We was hoping you could help with this issue what we are having with the server."
BETTER: "We were hoping you could help with this issue we're having with the server."

TEXT TO REWRITE:
PLACEHOLDER_FOR_INPUT_TEXT
TEMPLATE
)

    # Replace placeholder with actual input_text
    template=${template/PLACEHOLDER_FOR_INPUT_TEXT/$input_text}

    # Process with tptd
    if $use_tor; then
        tptd --tor "$model" "$template"
    else
        tptd "$model" "$template"
    fi
}

