#!/bin/zsh

#
# Script to interactively set OpenAI environment variables.
# Supports various providers like g4f, Gemini, OpenRouter, and custom Ollama endpoints.
#

# --- Color Definitions ---
# Centralized color codes for consistent styling.
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color
    
# --- UI Helper Functions ---

# Displays a centered header in a styled box.
# Arguments:
#   $1: The title string to display.
_display_header() {
    local title="$1"
    local header_width=38
    local clean_title
    # Remove ANSI color codes for accurate length calculation
    clean_title=$(echo "$title" | sed 's/\x1b\[[0-9;]*m//g')
    local title_len=${#clean_title}
    local padding_total=$((header_width - title_len))
    local padding_left=$((padding_total / 2))
    local padding_right=$((padding_total - padding_left))

    printf "\033c" >&2 # Reset terminal, writing to stderr.
    echo -e "${BOLD}${BLUE}+---------------------------------------+${NC}" >&2
    printf "${BOLD}${BLUE}|%*s${CYAN}%s${BLUE}%*s|${NC}\n" "$padding_left" "" "$title" "$padding_right" "" >&2
    echo -e "${BOLD}${BLUE}+---------------------------------------+${NC}" >&2
}

# Displays a standard confirmation screen with exported variables.
# Arguments:
#   $1: OPENAI_BASE_URL
#   $2: OPENAI_MODEL
#   $3: OPENAI_API_KEY
_display_confirmation() {
    local base_url="$1"
    local model="$2"
    local api_key="$3"

    _display_header "OpenAI Environment Variables"
    echo -e "${BOLD}Exported variables:${NC}"
    echo -e "${CYAN}OPENAI_BASE_URL:${NC} ${GREEN}'$base_url'${NC}"
    echo -e "${CYAN}OPENAI_MODEL:${NC} ${GREEN}'$model'${NC}"

    if [[ "$api_key" == "dummy-key" ]]; then
        echo -e "${CYAN}OPENAI_API_KEY:${NC} ${GREEN}'$api_key'${NC} (dummy key for g4f)"
    elif [[ "$api_key" == "nazOllama_colab" ]]; then
        echo -e "${CYAN}OPENAI_API_KEY:${NC} ${GREEN}'$api_key'${NC} (not required)"
    else
        # Mask API key for security
        echo -e "${CYAN}OPENAI_API_KEY:${NC} ${GREEN}'${api_key:0:4}****${api_key: -4}'${NC}"
                    fi
}

# Displays a numbered menu and prompts the user for a selection.
# Returns the selected item, or an empty string if the user goes back.
# Arguments:
#   $1: Menu title for the header.
#   $2: Prompt for the available options.
#   $3: Text for the "back" option (e.g., "← Go back to main menu").
#   $@: The rest of the arguments are the items to display in the menu.
_select_item() {
    local title="$1"
    local options_prompt="$2"
    local back_text="$3"
    shift 3
    local -a items=("$@")
    local selection

    while true; do
        _display_header "$title"
        echo -e "${BOLD}${GREEN}${options_prompt}${NC}" >&2
        echo "" >&2
        echo -e "  ${BOLD}${YELLOW}0)${NC} ${BOLD}${YELLOW}${back_text}${NC}" >&2
        echo "" >&2

                local i=1
        for item in "${items[@]}"; do
            # Use alternating colors for menu items for readability
                    if (( i % 2 == 0 )); then
                echo -e "  ${CYAN}$i)${NC} $item" >&2
                    else
                echo -e "  ${PURPLE}$i)${NC} $item" >&2
                    fi
                    ((i++))
        done
        echo "" >&2
                
        echo -e -n "${YELLOW}Select option (0 to go back, 1-$#items): ${NC}" >&2
                read selection
                
                if [[ "$selection" == "0" ]]; then
            echo -e "${BLUE}Going back...${NC}" >&2
            sleep 1.5
            return 1 # Signal to go back
                fi
                
        if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $#items ]; then
            echo -e "${RED}Error:${NC} Invalid selection" >&2
            sleep 1
                    continue
                fi
                
        # Return the selected item
        echo "${items[$selection]}"
        return 0
    done
}

# Retrieves API keys from a specified KWallet folder.
# If multiple keys exist, it prompts the user to select one.
# Arguments:
#   $1: The KWallet folder name (e.g., "gemini-api").
#   $2: The provider name for display purposes (e.g., "Gemini").
# Returns 0 on success, non-zero on failure.
# On success, prints two lines to stdout:
#   1. The selected entry name.
#   2. The corresponding API key.
_get_api_key_from_kwallet() {
    local wallet_folder="$1"
    local provider_name="$2"
    echo -e "${CYAN}Retrieving available ${provider_name} API keys from KWallet...${NC}" >&2

    # Query KWallet for entries, redirecting stderr to hide "No such folder" messages.
    local entries_str=$(kwallet-query --list-entries --folder "$wallet_folder" kdewallet 2>/dev/null)
    if [[ -z "$entries_str" ]]; then
        echo -e "${RED}Error:${NC} Failed to retrieve ${provider_name} API entries from KWallet!" >&2
        echo -e "Ensure:" >&2
        echo -e "1. KWallet is unlocked." >&2
        echo -e "2. The '$wallet_folder' folder exists in KWallet." >&2
                return 1
            fi
            
    local -a entries=("${(@f)entries_str}")
    local selected_entry

    if (( ${#entries[@]} > 1 )); then
        if ! selected_entry=$(_select_item "${provider_name} API Key Selection" "Available API Keys:" "← Go back to provider selection" "${entries[@]}"); then
            return 2 # User selected "go back"
        fi
    else
        selected_entry="${entries[1]}"
        echo -e "${CYAN}Using the only available API key: ${GREEN}$selected_entry${NC}" >&2
    fi

    local api_key=$(kwallet-query --folder "$wallet_folder" --read-password "$selected_entry" kdewallet 2>/dev/null)
    if [[ -z "$api_key" ]]; then
        echo -e "${RED}Error:${NC} Failed to retrieve API key for '$selected_entry' from KWallet." >&2
                    return 1
                fi
                
    # Return both the entry name and the key
    echo "$selected_entry"
    echo "$api_key"
    return 0
}

# --- Provider-Specific Handlers ---

_handle_g4f() {
    local g4f_base_url="http://localhost:1337"
    if ! curl -s "$g4f_base_url/v1/models" > /dev/null; then
        echo -e "${RED}Error:${NC} Cannot connect to g4f server at $g4f_base_url" >&2
                return 1
            fi
            
    while true; do
        echo -e "${CYAN}Fetching available providers...${NC}" >&2
        local providers_str=$(curl -s -X GET "$g4f_base_url/v1/models" -H 'accept: application/json' | jq -r '.data[] | select(.provider == true) | .id' | sort)
        if [[ -z "$providers_str" ]]; then
            echo -e "${RED}Error:${NC} No providers found from g4f server." >&2
                return 1
            fi
        local -a providers=("${(@f)providers_str}")

        local provider
        if ! provider=$(_select_item "g4f Provider Selection" "Available providers:" "← Go back to main menu" "${providers[@]}"); then
            return 2 # User chose to go back to the main menu
        fi
        
        echo -e "${CYAN}Fetching models for provider '$provider'...${NC}" >&2
        local models_str=$(curl -s -X GET "$g4f_base_url/api/$provider/models" -H 'accept: application/json' | jq -r '.data[] | .id' | sort)
        if [[ -z "$models_str" ]]; then
            echo -e "${RED}Error:${NC} No models found for provider '$provider'." >&2
            sleep 2
            continue
        fi
        local -a models=("${(@f)models_str}")

        model=$(_select_item "g4f Model Selection" "Available models for $provider:" "← Go back to provider selection" "${models[@]}")
        if [[ $? -eq 0 ]]; then
            api_key="dummy-key"
            base_url="$g4f_base_url/api/$provider"
            return 0 # Success
        fi
    done
}

_handle_gemini() {
    local key_info_str
    key_info_str=$(_get_api_key_from_kwallet "gemini-api" "Gemini")
    local ret_status=$?
    if [[ $ret_status -ne 0 ]]; then
        [[ $ret_status -eq 2 ]] && return 2 # Pass "go back" signal up
        return 1 # It was a hard error
    fi
    # The last line of the output is the API key.
    api_key=$(echo "$key_info_str" | tail -n 1)
    
    base_url="https://generativelanguage.googleapis.com/v1beta/openai"
    
    echo -e "${CYAN}Fetching available models from Gemini...${NC}" >&2
    local models_response=$(curl -s -X GET "${base_url}/models" -H "Authorization: Bearer $api_key")
    if echo "$models_response" | grep -q "error"; then
        echo -e "${RED}Error:${NC} Failed to fetch models from Gemini API."
        echo -e "API Response: $(echo "$models_response" | jq -r .error.message)"
                return 1
            fi
            
    local models_str=$(echo "$models_response" | jq -r '.data[].id' 2>/dev/null | sort)
    if [[ -z "$models_str" ]]; then
        echo -e "${RED}Error:${NC} No models found or failed to parse response."
                    return 1
                fi
    local -a models=("${(@f)models_str}")
    
    if ! model=$(_select_item "Gemini Model Selection" "Available models:" "← Go back to provider selection" "${models[@]}"); then
        return 2 # Go back to main
    fi
    return 0 # Success
}

_handle_openrouter() {
    local key_info_str
    key_info_str=$(_get_api_key_from_kwallet "openrouter-api" "OpenRouter")
    local ret_status=$?
    if [[ $ret_status -ne 0 ]]; then
        [[ $ret_status -eq 2 ]] && return 2 # Pass "go back" up
        return 1 # It was a hard error
    fi
    
    local -a key_info=("${(@f)key_info_str}")
    local selected_entry="${key_info[1]}"
    api_key="${key_info[2]}"

    base_url="https://openrouter.ai/api/v1"

    echo -e "${CYAN}Fetching available models from OpenRouter...${NC}" >&2
    local response_file=$(mktemp)
    curl -s -X GET "${base_url}/models" -H "Authorization: Bearer $api_key" > "$response_file"
    
    if [[ $(jq -r 'has("error")' "$response_file") == "true" ]]; then
        echo -e "${RED}Error:${NC} Failed to fetch models from OpenRouter API." >&2
        echo -e "API Response: $(jq -r '.error.message' "$response_file")" >&2
        rm "$response_file"
                return 1
            fi
            
    # Conditionally filter for free models if the 'OPENROUTER_API_FREE' key is selected.
    local models_str
    local menu_title="OpenRouter Model Selection"
    if [[ "$selected_entry" == "OPENROUTER_API_FREE" ]]; then
        echo -e "${CYAN}Filtering for free models for key '${GREEN}$selected_entry${NC}'...${NC}" >&2
        models_str=$(jq -r '.data[] | select(.pricing.prompt == "0" and .pricing.completion == "0") | .id' "$response_file" | sort)
        menu_title="OpenRouter Model Selection (Free)"
    else
        echo -e "${CYAN}Fetching all models for key '${GREEN}$selected_entry${NC}'...${NC}" >&2
        models_str=$(jq -r '.data[].id' "$response_file" | sort)
    fi
    rm "$response_file"

    if [[ -z "$models_str" ]]; then
        echo -e "${RED}Error:${NC} No models found or failed to parse response." >&2
                return 1
            fi
    local -a models=("${(@f)models_str}")

    if ! model=$(_select_item "$menu_title" "Available models:" "← Go back to provider selection" "${models[@]}"); then
        return 2 # Go back to main
    fi
    return 0 # Success
}

_handle_nazollama_colab() {
    echo -e "${CYAN}Fetching nazOllama_colab base URL...${NC}" >&2
            local ollama_base_url=$(curl -sL https://nazkvhub.nazdridoy.workers.dev/v1/query/ollama-tunnel | jq -r '.url')
            if [[ -z "$ollama_base_url" || "$ollama_base_url" == "null" ]]; then
                echo -e "${RED}Error:${NC} Failed to fetch nazOllama_colab base URL."
                return 1
            fi
            
            base_url="$ollama_base_url/v1"

            if ! curl -s "$base_url/models" > /dev/null; then
                echo -e "${RED}Error:${NC} Cannot connect to nazOllama_colab server at $base_url"
                return 1
            fi

            echo -e "${CYAN}Fetching available models from nazOllama_colab...${NC}"
            local models_response=$(curl -s -X GET "${base_url}/models")
            if echo "$models_response" | grep -q "error"; then
        echo -e "${RED}Error:${NC} Failed to fetch models from nazOllama_colab API."
                echo -e "API Response: $models_response"
                return 1
            fi

    local models_str=$(echo "$models_response" | jq -r '.data[].id' 2>/dev/null | sort)
    if [[ -z "$models_str" ]]; then
        echo -e "${RED}Error:${NC} No models found or failed to parse response."
                return 1
            fi
    local -a models=("${(@f)models_str}")

    if ! model=$(_select_item "nazOllama_colab Model Selection" "Available models:" "← Go back to provider selection" "${models[@]}"); then
        return 2 # Go back to main
    fi

    api_key="nazOllama_colab" # This provider does not require an API key
    return 0 # Success
}

# --- Main Function ---

# Main function to set OpenAI environment variables based on user selection.
setOpenAIEnv() {
    # These variables will be populated by the provider handlers.
    local model=""
    local api_key=""
    local base_url=""

    while true; do
        _display_header "OpenAI Environment Setup"
        echo -e "${BOLD}${GREEN}Select Provider:${NC}" >&2
        
        local main_menu_options=(
            "g4f (Local GPT4Free Server)"
            "Gemini API"
            "OpenRouter"
            "nazOllama_colab"
        )
        
            local i=1
        for item in "${main_menu_options[@]}"; do
                if (( i % 2 == 0 )); then
                echo -e "  ${CYAN}$i)${NC} $item" >&2
                else
                echo -e "  ${PURPLE}$i)${NC} $item" >&2
                fi
                ((i++))
        done
        
        echo "" >&2
        echo -e "  ${RED}0)${NC} Unset all environment variables" >&2
        echo "" >&2
        
        local choice=''
        echo -e -n "${YELLOW}Select provider (0-4): ${NC}" >&2
        read choice

        local handler_status=0
        case "$choice" in
            "0")
                unset OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
                _display_header "OpenAI Environment Variables"
                echo -e "${BOLD}${GREEN}All OpenAI environment variables have been unset.${NC}" >&2
                return 0
                ;;
            "1")
                _handle_g4f; handler_status=$?
                ;;
            "2")
                _handle_gemini; handler_status=$?
                ;;
            "3")
                _handle_openrouter; handler_status=$?
                ;;
            "4")
                _handle_nazollama_colab; handler_status=$?
            ;;
        *)
                echo -e "${RED}Error:${NC} Invalid selection." >&2
                sleep 1
                continue
            ;;
    esac
    
        if [[ $handler_status -eq 0 ]]; then
            break # Success, break main loop
        elif [[ $handler_status -eq 1 ]]; then
            # A hard error occurred in the handler
            echo -e "${RED}An error occurred. Returning to main menu...${NC}" >&2
            sleep 2
        fi
        # If status is 2 (or anything else), it means "go back", so we just continue the loop.
    done
    
    # Export the environment variables for the current shell session
    export OPENAI_API_KEY="$api_key"
    export OPENAI_BASE_URL="$base_url"
    export OPENAI_MODEL="$model"
    
    _display_confirmation "$base_url" "$model" "$api_key"
    return 0
}
