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

Text to rewrite: $input_text"

    # Process with tptd
    if $use_tor; then
        tptd --tor "$model" "$template"
    else
        tptd "$model" "$template"
    fi
}

