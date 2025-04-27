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
    echo -e "  ${CYAN}1)${NC} g4f (Local GPT4Free Server)"
    echo -e "  ${PURPLE}2)${NC} Gemini API"
    echo ""
    
    # Get user selection
    echo -e -n "${YELLOW}Select provider (1-2): ${NC}"
    read provider_choice
    
    case "$provider_choice" in
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
                echo -e "${BOLD}${BLUE}|       ${CYAN}g4f Model Selection${BLUE}            |${NC}"
                echo -e "${BOLD}${BLUE}+-------------------------------------+${NC}"
                echo -e "${BOLD}Selected provider:${NC} ${GREEN}'$provider'${NC}"
                
                # Get available models for the selected provider
                echo -e "${CYAN}Fetching models for provider '$provider'...${NC}"
                local models=$(curl -s -X 'GET' "$g4f_base_url/api/$provider/models" \
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
            
            # Get API key from wallet
            local timeout=5
            echo -e "${CYAN}Retrieving Gemini API key...${NC}"
            
            # Use timeout command if available
            if command -v timeout >/dev/null 2>&1; then
                api_key=$(timeout $timeout kwalletcli -f "gemini-api" -e "GEMINI_API" 2>/dev/null)
            else
                api_key=$(kwalletcli -f "gemini-api" -e "GEMINI_API" 2>/dev/null)
            fi
            
            # Verify the API key was retrieved
            if [[ -z "$api_key" ]]; then
                echo -e "${RED}Error:${NC} Failed to retrieve Gemini API key from KWallet!"
                echo -e "Ensure:"
                echo -e "1. KWallet is unlocked"
                echo -e "2. Entry exists in 'gemini-api' folder:"
                echo -e "   - GEMINI_API"
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
            local models=$(echo "$models_response" | jq -r '.data[].id' 2>/dev/null)
            
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
            echo -e -n "${YELLOW}Select model (1-$((i-1))): ${NC}"
            read selection
            
            # Validate selection
            if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $((i-1)) ]; then
                echo -e "${RED}Error:${NC} Invalid selection"
                return 1
            fi
            
            # Arrays in zsh are 1-indexed, adjust the index
            model="${model_array[$selection]}"
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
    else
        echo -e "${CYAN}OPENAI_API_KEY:${NC} ${GREEN}'${OPENAI_API_KEY:0:4}****${OPENAI_API_KEY: -4}'${NC}"
    fi
}
