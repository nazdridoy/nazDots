#!/bin/zsh

# Function to set OpenAI environment variables based on selected provider
setOpenAIEnv() {
    local provider_choice=""
    local provider=""
    local model=""
    local api_key=""
    local base_url=""
    
    # Define color codes
    local BLUE='\033[0;34m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local CYAN='\033[0;36m'
    local PURPLE='\033[0;35m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m' # No Color
    
    # Clear screen and show header
    clear
    printf "\033c"  # ANSI escape sequence to reset terminal
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    echo -e "${BOLD}${BLUE}|       ${CYAN}OpenAI Environment Setup${BLUE}      |${NC}"
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    
    # Provider selection
    echo -e "${BOLD}${GREEN}Select Provider:${NC}"
    echo -e "  ${RED}0)${NC} Unset all environment variables"
    echo -e "  ${CYAN}1)${NC} g4f (Local GPT4Free Server)"
    echo -e "  ${PURPLE}2)${NC} Gemini API"
    echo -e "  ${GREEN}3)${NC} OpenRouter"
    echo -e "  ${BLUE}4)${NC} nazOllama_colab"
    echo ""
    
    # Get user selection
    echo -e -n "${YELLOW}Select provider (0-4): ${NC}"
    read provider_choice
    
    case "$provider_choice" in
        "0")
            # Unset all environment variables
            unset OPENAI_API_KEY
            unset OPENAI_BASE_URL
            unset OPENAI_MODEL
            
            # Show confirmation
            clear
            printf "\033c"
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
            echo -e "${BOLD}${BLUE}|     ${CYAN}OpenAI Environment Variables${BLUE}     |${NC}"
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
            echo -e "${BOLD}${GREEN}All OpenAI environment variables have been unset.${NC}"
            return 0
            ;;
        "1")
            # g4f flow
            local g4f_base_url="http://localhost:1337"
            
            # Check if g4f server is running
            if ! curl -s "$g4f_base_url/v1/models" > /dev/null; then
                echo -e "${RED}Error:${NC} Cannot connect to g4f server at $g4f_base_url"
                echo -e "Make sure the server is running and accessible"
                return 1
            fi
            
            # Provider selection loop
            while true; do
                clear
                printf "\033c"  # Reset terminal
                echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
                echo -e "${BOLD}${BLUE}|       ${CYAN}g4f Provider Selection${BLUE}         |${NC}"
                echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
                
                # Get available providers
                echo -e "${CYAN}Fetching available providers...${NC}"
                local providers=$(curl -s -X 'GET' "$g4f_base_url/v1/models" \
                    -H 'accept: application/json' | jq -r '.data[] | select(.provider == true) | .id')
                
                if [[ -z "$providers" ]]; then
                    echo -e "${RED}Error:${NC} No providers found"
                    return 1
                fi
                
                # Create a numbered menu for provider selection
                echo -e "${BOLD}${GREEN}Available providers:${NC}"
                echo ""  # Add spacing before provider list
                echo -e "  ${BOLD}${YELLOW}0)${NC} ${BOLD}${YELLOW}← Go back to main menu${NC}"
                echo ""  # Add spacing after back option
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
                echo -e -n "${YELLOW}Select provider (0 to go back, 1-$((i-1))): ${NC}"
                read selection
                
                # Check if user wants to go back
                if [[ "$selection" == "0" ]]; then
                    echo -e "${BLUE}Going back to main menu...${NC}"
                    sleep 1.5  # Longer pause before clearing
                    setOpenAIEnv  # Restart the function
                    return 0
                fi
                
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
                echo -e "${BOLD}${BLUE}|       ${CYAN}g4f Model Selection${BLUE}            |${NC}"
                echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
                echo -e "${BOLD}Selected provider:${NC} ${GREEN}'$provider'${NC}"
                
                # Get available models for the selected provider
                echo -e "${CYAN}Fetching models for provider '$provider'...${NC}"
                local models=$(curl -s -X 'GET' "$g4f_base_url/api/$provider/models" \
                    -H 'accept: application/json' | jq -r '.data[] | .id' | sort)
                
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
            
            # Set environment variables for g4f
            api_key="dummy-key"
            base_url="$g4f_base_url/api/$provider"
            
            ;;
        "2")
            # Gemini flow
            base_url="https://generativelanguage.googleapis.com/v1beta/openai"
            
            # Get available entries in the gemini-api folder
            local wallet_folder="gemini-api"
            echo -e "${CYAN}Retrieving available Gemini API keys from KWallet...${NC}"
            
            local entries=$(kwallet-query --list-entries --folder "$wallet_folder" kdewallet 2>/dev/null)
            
            # Check if we got any entries
            if [[ -z "$entries" ]]; then
                echo -e "${RED}Error:${NC} Failed to retrieve Gemini API entries from KWallet!"
                echo -e "Ensure:"
                echo -e "1. KWallet is unlocked"
                echo -e "2. The '$wallet_folder' folder exists in KWallet"
                return 1
            fi
            
            # Create array of entries
            local entry_array=()
            while read -r entry; do
                if [[ ! -z "$entry" ]]; then
                    entry_array+=("$entry")
                fi
            done <<< "$entries"
            
            local entry_count=${#entry_array[@]}
            local selected_entry=""
            
            # If there's more than one entry, let user choose
            if [[ $entry_count -gt 1 ]]; then
                clear
                printf "\033c"
                echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
                echo -e "${BOLD}${BLUE}|       ${CYAN}Gemini API Key Selection${BLUE}       |${NC}"
                echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
                
                echo -e "${BOLD}${GREEN}Available API Keys:${NC}"
                echo ""
                echo -e "  ${BOLD}${YELLOW}0)${NC} ${BOLD}${YELLOW}← Go back to provider selection${NC}"
                echo ""
                
                local i=1
                for entry in "${entry_array[@]}"; do
                    # Use different colors for alternating rows
                    if (( i % 2 == 0 )); then
                        echo -e "  ${CYAN}$i)${NC} $entry"
                    else
                        echo -e "  ${PURPLE}$i)${NC} $entry"
                    fi
                    ((i++))
                done
                echo ""
                
                # Get user selection
                echo -e -n "${YELLOW}Select API Key (0 to go back, 1-$entry_count): ${NC}"
                read selection
                
                # Check if user wants to go back
                if [[ "$selection" == "0" ]]; then
                    echo -e "${BLUE}Going back to provider selection...${NC}"
                    sleep 1.5
                    setOpenAIEnv  # Restart the function
                    return 0
                fi
                
                # Validate selection
                if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $entry_count ]; then
                    echo -e "${RED}Error:${NC} Invalid selection"
                    return 1
                fi
                
                # Get selected entry
                selected_entry="${entry_array[$selection]}"
            else
                # Only one entry, use it directly
                selected_entry="${entry_array[1]}"
                echo -e "${CYAN}Using the only available API key: ${GREEN}$selected_entry${NC}"
            fi
            
            # Get the API key for the selected entry
            api_key=$(kwallet-query --folder "$wallet_folder" --read-password "$selected_entry" kdewallet 2>/dev/null)
            
            # Verify the API key was retrieved
            if [[ -z "$api_key" ]]; then
                echo -e "${RED}Error:${NC} Failed to retrieve Gemini API key for '$selected_entry' from KWallet!"
                return 1
            fi
            
            # Fetch available models
            echo -e "${CYAN}Fetching available models from Gemini...${NC}"
            local models_response=$(curl -s -X GET \
                "${base_url}/models" \
                -H "Authorization: Bearer $api_key")
            
            # Check for errors in the response
            if echo "$models_response" | grep -q "error"; then
                echo -e "${RED}Error:${NC} Failed to fetch models from Gemini API"
                echo -e "API Response: $models_response"
                return 1
            fi
            
            # Parse models from response
            local models=$(echo "$models_response" | jq -r '.data[].id' 2>/dev/null | sort)
            
            if [[ -z "$models" ]]; then
                echo -e "${RED}Error:${NC} No models found or failed to parse response"
                return 1
            fi
            
            # Create a numbered menu for model selection
            clear
            printf "\033c"
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
            echo -e "${BOLD}${BLUE}|       ${CYAN}Gemini Model Selection${BLUE}         |${NC}"
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
            
            echo -e "${BOLD}${GREEN}Available models:${NC}"
            echo ""  # Add spacing before model list
            echo -e "  ${BOLD}${YELLOW}0)${NC} ${BOLD}${YELLOW}← Go back to provider selection${NC}"
            echo ""  # Add spacing after back option
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
            echo ""  # Add spacing after model list
            
            # Get user selection
            echo -e -n "${YELLOW}Select model (0 to go back, 1-$((i-1))): ${NC}"
            read selection
            
            # Check if user wants to go back
            if [[ "$selection" == "0" ]]; then
                echo -e "${BLUE}Going back to provider selection...${NC}"
                sleep 1.5  # Longer pause before clearing
                setOpenAIEnv  # Restart the function
                return 0
            fi
            
            # Validate selection
            if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $((i-1)) ]; then
                echo -e "${RED}Error:${NC} Invalid selection"
                return 1
            fi
            
            # Arrays in zsh are 1-indexed, adjust the index
            model="${model_array[$selection]}"
            ;;
        "3")
            # OpenRouter flow
            base_url="https://openrouter.ai/api/v1"
            
            # Get available entries in the openrouter-api folder
            local wallet_folder="openrouter-api"
            echo -e "${CYAN}Retrieving available OpenRouter API keys from KWallet...${NC}"
            
            local entries=$(kwallet-query --list-entries --folder "$wallet_folder" kdewallet 2>/dev/null)
            
            # Check if we got any entries
            if [[ -z "$entries" ]]; then
                echo -e "${RED}Error:${NC} Failed to retrieve OpenRouter API entries from KWallet!"
                echo -e "Ensure:"
                echo -e "1. KWallet is unlocked"
                echo -e "2. The '$wallet_folder' folder exists in KWallet"
                return 1
            fi
            
            # Create array of entries
            local entry_array=()
            while read -r entry; do
                if [[ ! -z "$entry" ]]; then
                    entry_array+=("$entry")
                fi
            done <<< "$entries"
            
            local entry_count=${#entry_array[@]}
            local selected_entry=""
            
            # If there's more than one entry, let user choose
            if [[ $entry_count -gt 1 ]]; then
                clear
                printf "\033c"
                echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
                echo -e "${BOLD}${BLUE}|     ${CYAN}OpenRouter API Key Selection${BLUE}     |${NC}"
                echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
                
                echo -e "${BOLD}${GREEN}Available API Keys:${NC}"
                echo ""
                echo -e "  ${BOLD}${YELLOW}0)${NC} ${BOLD}${YELLOW}← Go back to provider selection${NC}"
                echo ""
                
                local i=1
                for entry in "${entry_array[@]}"; do
                    # Use different colors for alternating rows
                    if (( i % 2 == 0 )); then
                        echo -e "  ${CYAN}$i)${NC} $entry"
                    else
                        echo -e "  ${PURPLE}$i)${NC} $entry"
                    fi
                    ((i++))
                done
                echo ""
                
                # Get user selection
                echo -e -n "${YELLOW}Select API Key (0 to go back, 1-$entry_count): ${NC}"
                read selection
                
                # Check if user wants to go back
                if [[ "$selection" == "0" ]]; then
                    echo -e "${BLUE}Going back to provider selection...${NC}"
                    sleep 1.5
                    setOpenAIEnv  # Restart the function
                    return 0
                fi
                
                # Validate selection
                if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $entry_count ]; then
                    echo -e "${RED}Error:${NC} Invalid selection"
                    return 1
                fi
                
                # Get selected entry
                selected_entry="${entry_array[$selection]}"
            else
                # Only one entry, use it directly
                selected_entry="${entry_array[1]}"
                echo -e "${CYAN}Using the only available API key: ${GREEN}$selected_entry${NC}"
            fi
            
            # Get the API key for the selected entry
            api_key=$(kwallet-query --folder "$wallet_folder" --read-password "$selected_entry" kdewallet 2>/dev/null)
            
            # Verify the API key was retrieved
            if [[ -z "$api_key" ]]; then
                echo -e "${RED}Error:${NC} Failed to retrieve OpenRouter API key for '$selected_entry' from KWallet!"
                return 1
            fi
            
            # Create a temporary file
            local temp_file=$(mktemp)
            
            # Fetch available models and save to temporary file
            echo -e "${CYAN}Fetching available models from OpenRouter...${NC}"
            curl -s -X GET "${base_url}/models" \
                -H "Authorization: Bearer $api_key" > "$temp_file" 2>/dev/null
            
            # Check if the file has an error field
            if [[ $(jq -r 'has("error")' "$temp_file") == "true" ]]; then
                echo -e "${RED}Error:${NC} Failed to fetch models from OpenRouter API"
                echo -e "API Response: $(jq -r '.error.message' "$temp_file")"
                rm "$temp_file"
                return 1
            fi
            
            # Extract free models to another temp file
            local models_file=$(mktemp)
            jq -r '.data[] | 
                select(.pricing.prompt == "0" and 
                       .pricing.completion == "0" and 
                       .pricing.request == "0" and 
                       .pricing.image == "0" and 
                       .pricing.web_search == "0" and 
                       .pricing.internal_reasoning == "0") | 
                .id' "$temp_file" | sort > "$models_file" 2>/dev/null
            
            # Check if any free models were found
            if [[ ! -s "$models_file" ]]; then
                echo -e "${RED}Error:${NC} No free models found or failed to parse response"
                rm "$temp_file" "$models_file"
                return 1
            fi
            
            # Read models from the file
            local models=$(cat "$models_file")
            
            # Clean up temp files
            rm "$temp_file" "$models_file"
            
            # Create a numbered menu for model selection
            clear
            printf "\033c"
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
            echo -e "${BOLD}${BLUE}|     ${CYAN}OpenRouter Model Selection${BLUE}       |${NC}"
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
            echo -e "${BOLD}${GREEN}Free models only:${NC}"
            
            echo ""  # Add spacing before model list
            echo -e "  ${BOLD}${YELLOW}0)${NC} ${BOLD}${YELLOW}← Go back to provider selection${NC}"
            echo ""  # Add spacing after back option
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
            echo ""  # Add spacing after model list
            
            # Get user selection
            echo -e -n "${YELLOW}Select model (0 to go back, 1-$((i-1))): ${NC}"
            read selection
            
            # Check if user wants to go back
            if [[ "$selection" == "0" ]]; then
                echo -e "${BLUE}Going back to provider selection...${NC}"
                sleep 1.5  # Longer pause before clearing
                setOpenAIEnv  # Restart the function
                return 0
            fi
            
            # Validate selection
            if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $((i-1)) ]; then
                echo -e "${RED}Error:${NC} Invalid selection"
                return 1
            fi
            
            # Arrays in zsh are 1-indexed, adjust the index
            model="${model_array[$selection]}"
            ;;
        "4")
            # nazOllama_colab flow
            echo -e "${CYAN}Fetching nazOllama_colab base URL...${NC}"
            local ollama_base_url=$(curl -sL https://nazkvhub.nazdridoy.workers.dev/v1/query/ollama-tunnel | jq -r '.url')

            if [[ -z "$ollama_base_url" || "$ollama_base_url" == "null" ]]; then
                echo -e "${RED}Error:${NC} Failed to fetch nazOllama_colab base URL."
                return 1
            fi
            
            base_url="$ollama_base_url/v1"

            # Check if ollama server is running
            if ! curl -s "$base_url/models" > /dev/null; then
                echo -e "${RED}Error:${NC} Cannot connect to nazOllama_colab server at $base_url"
                echo -e "Make sure the server is running and accessible"
                return 1
            fi

            # Fetch available models
            echo -e "${CYAN}Fetching available models from nazOllama_colab...${NC}"
            local models_response=$(curl -s -X GET "${base_url}/models")

            # Check for errors in the response
            if echo "$models_response" | grep -q "error"; then
                echo -e "${RED}Error:${NC} Failed to fetch models from nazOllama_colab API"
                echo -e "API Response: $models_response"
                return 1
            fi

            # Parse models from response
            local models=$(echo "$models_response" | jq -r '.data[].id' 2>/dev/null | sort)

            if [[ -z "$models" ]]; then
                echo -e "${RED}Error:${NC} No models found or failed to parse response"
                return 1
            fi

            # Create a numbered menu for model selection
            clear
            printf "\033c"
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
            echo -e "${BOLD}${BLUE}|    ${CYAN}nazOllama_colab Model Selection${BLUE}     |${NC}"
            echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"

            echo -e "${BOLD}${GREEN}Available models:${NC}"
            echo ""
            echo -e "  ${BOLD}${YELLOW}0)${NC} ${BOLD}${YELLOW}← Go back to provider selection${NC}"
            echo ""
            local i=1
            local model_array=()
            while read -r m; do
                if (( i % 2 == 0 )); then
                    echo -e "  ${CYAN}$i)${NC} $m"
                else
                    echo -e "  ${PURPLE}$i)${NC} $m"
                fi
                model_array+=("$m")
                ((i++))
            done <<< "$models"
            echo ""

            # Get user selection
            echo -e -n "${YELLOW}Select model (0 to go back, 1-$((i-1))): ${NC}"
            read selection

            if [[ "$selection" == "0" ]]; then
                echo -e "${BLUE}Going back to provider selection...${NC}"
                sleep 1.5
                setOpenAIEnv
                return 0
            fi

            if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $((i-1)) ]; then
                echo -e "${RED}Error:${NC} Invalid selection"
                return 1
            fi

            model="${model_array[$selection]}"
            api_key="nazOllama_colab" # nazOllama_colab doesn't require an API key
            ;;
        *)
            echo -e "${RED}Error:${NC} Invalid selection"
            return 1
            ;;
    esac
    
    # Export the environment variables
    export OPENAI_API_KEY="$api_key"
    export OPENAI_BASE_URL="$base_url"
    export OPENAI_MODEL="$model"
    
    # Show confirmation
    clear
    printf "\033c"
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    echo -e "${BOLD}${BLUE}|     ${CYAN}OpenAI Environment Variables${BLUE}     |${NC}"
    echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
    echo -e "${BOLD}Exported variables:${NC}"
    
    # Show base URL
    echo -e "${CYAN}OPENAI_BASE_URL:${NC} ${GREEN}'$OPENAI_BASE_URL'${NC}"
    
    # Show model
    echo -e "${CYAN}OPENAI_MODEL:${NC} ${GREEN}'$OPENAI_MODEL'${NC}"
    
    # Show API key (masked except for first 4 and last 4 characters)
    if [[ "$api_key" == "dummy-key" ]]; then
        echo -e "${CYAN}OPENAI_API_KEY:${NC} ${GREEN}'$OPENAI_API_KEY'${NC} (dummy key for g4f)"
    elif [[ "$api_key" == "nazOllama_colab" ]]; then
        echo -e "${CYAN}OPENAI_API_KEY:${NC} ${GREEN}'$OPENAI_API_KEY'${NC} (not required)"
    else
        echo -e "${CYAN}OPENAI_API_KEY:${NC} ${GREEN}'${OPENAI_API_KEY:0:4}****${OPENAI_API_KEY: -4}'${NC}"
    fi
}
