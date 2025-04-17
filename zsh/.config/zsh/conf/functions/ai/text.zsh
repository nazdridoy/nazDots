# AI-powered text rewriter that preserves tone
rewrite() {
    local model="sonar-pro"
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
                echo "Available models (same as tptb):"
                echo "  blackboxai-pro, 1     : blackboxai-pro"
                echo "  blackboxai, 2         : blackboxai"
                echo "  claude-3-haiku, 3     : claude-3-haiku"
                echo "  claude-3.5-sonnet, 4  : claude-3.5-sonnet"
                echo "  claude-3.7-sonnet, 5  : claude-3.7-sonnet"
                echo "  deepseek-chat, 6      : deepseek-chat"
                echo "  deepseek-r1, 7        : deepseek-r1"
                echo "  deepseek-v3, 8        : deepseek-v3"
                echo "  evil, 9               : evil"
                echo "  glm-4, 10             : glm-4"
                echo "  gpt-4, 11             : gpt-4"
                echo "  gpt-4o-mini, 12       : gpt-4o-mini"
                echo "  gpt-4o, 13            : gpt-4o"
                echo "  hermes-3, 14          : hermes-3"
                echo "  lfm-40b, 15           : lfm-40b"
                echo "  llama-3.1-70b, 16     : llama-3.1-70b"
                echo "  llama-3.3-70b, 17     : llama-3.3-70b"
                echo "  llama-4-scout, 18     : llama-4-scout"
                echo "  meta-ai, 19           : meta-ai"
                echo "  o3-mini, 20           : o3-mini"
                echo "  r1-1776, 21           : r1-1776"
                echo "  sonar-pro, 22         : sonar-pro"
                echo "  sonar-reasoning-pro, 23: sonar-reasoning-pro"
                echo ""
                echo "Examples:"
                echo "  echo \"your text\" | rewrite"
                echo "  echo \"angry message\" | rewrite --tor claude-3.7-sonnet"
                echo "  cat file.txt | rewrite --tor 5"
                echo ""
                echo "Default: sonar-pro"
                return 0
                ;;
            blackboxai-pro|1|blackboxai|2|claude-3-haiku|3|claude-3.5-sonnet|4|claude-3.7-sonnet|5|deepseek-chat|6|deepseek-r1|7|deepseek-v3|8|evil|9|glm-4|10|gpt-4|11|gpt-4o-mini|12|gpt-4o|13|hermes-3|14|lfm-40b|15|llama-3.1-70b|16|llama-3.3-70b|17|llama-4-scout|18|meta-ai|19|o3-mini|20|r1-1776|21|sonar-pro|22|sonar-reasoning-pro|23)
                model="$1"
                shift
                break
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

    # Create a temporary file to store the result
    local temp_file=$(mktemp)
    
    # Process with tptb
    if $use_tor; then
        tptb --tor "$model" "$template" > "$temp_file"
    else
        tptb "$model" "$template" > "$temp_file"
    fi
    
    # Display the result
    cat "$temp_file"
    
    # Ask if user wants to copy to clipboard
    echo ""
    read -q "copy?Copy to clipboard? (y/n) " || { echo ""; rm "$temp_file"; return 0; }
    echo ""
    
    # Clean the result - remove loading indicators and extra lines
    cat "$temp_file" | grep -v "Loading" | grep -v $'^\xe2' | xclip -selection clipboard
    echo "Copied to clipboard."
    
    # Clean up
    rm "$temp_file"
}

