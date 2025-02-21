#!/bin/bash

# ANSI color codes
COLOR_DEBUG='\033[1;36m'    # Cyan for [DEBUG]
COLOR_PATH='\033[1;33m'     # Yellow for file paths
COLOR_CMD='\033[1;35m'      # Magenta for commands
COLOR_VAR='\033[1;32m'      # Green for variable names/values
COLOR_RESET='\033[0m'       # Reset color

# Function to print debug messages
debug() {
    echo -e "${COLOR_DEBUG}[DEBUG]${COLOR_RESET} $1"
}

# Function to colorize paths
colorize_path() {
    local text="$1"
    # Replace quoted strings with colored versions
    local result=""
    local in_quote=false
    local char prev_char=""
    
    for (( i=0; i<${#text}; i++ )); do
        char="${text:$i:1}"
        if [[ $char == '"' && $prev_char != '\' ]]; then
            if $in_quote; then
                result+="\"${COLOR_RESET}"
                in_quote=false
            else
                result+="${COLOR_PATH}\""
                in_quote=true
            fi
        else
            result+="$char"
        fi
        prev_char="$char"
    done
    echo -e "$result"
}

# Function to colorize commands
colorize_cmd() {
    local cmd="$1"
    # First colorize the command name
    if [[ $cmd =~ ^(mkdir|mv) ]]; then
        cmd="${COLOR_CMD}${BASH_REMATCH[1]}${COLOR_RESET}${cmd:${#BASH_REMATCH[1]}}"
    fi
    # Then colorize the paths
    colorize_path "$cmd"
}

# Function to prompt for final confirmation
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo    # Move to a new line
    # Default to 'n' if no input is provided
    REPLY=${REPLY:-n}
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi
}

# Function to check if a directory exists
check_dir() {
    local dir="$1"
    local msg="$2"
    if [ ! -d "$dir" ]; then
        echo -e "${COLOR_DEBUG}[ERROR]${COLOR_RESET} $msg: ${COLOR_PATH}$dir${COLOR_RESET}"
        exit 1
    fi
}

# Function to execute command with error checking
execute_cmd() {
    local cmd="$1"
    local error_msg="$2"
    
    if ! eval "$cmd"; then
        echo -e "${COLOR_DEBUG}[ERROR]${COLOR_RESET} $error_msg"
        exit 1
    fi
    debug "Executed: $(colorize_cmd "$cmd")"
}

# Check if the correct number of arguments is provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <pkgname> <config dir>"
    exit 1
fi

# Assign arguments to variables
PKGNAME="$1"
CONFIG_DIR="$2"

# Read the target directory from .stowrc
TARGET_DIR=$(grep --no-messages '^--target=' .stowrc | cut -d'=' -f2)

# Expand the TARGET_DIR variable to its actual path
TARGET_DIR=$(eval echo "$TARGET_DIR")

# Check if the target directory was found
if [ -z "$TARGET_DIR" ]; then
    echo "Target directory not found in .stowrc"
    exit 1
fi

# Debug output for the target directory
debug "TARGET_DIR: ${COLOR_VAR}$TARGET_DIR${COLOR_RESET}"

# Check if the configuration directory exists
check_dir "$CONFIG_DIR" "Configuration directory does not exist"

# Check if the target directory exists
check_dir "$TARGET_DIR" "Target directory does not exist"

# Check if the package directory already exists
if [ -d "$PKGNAME" ]; then
    echo -e "${COLOR_DEBUG}[ERROR]${COLOR_RESET} Package directory already exists: ${COLOR_PATH}$PKGNAME${COLOR_RESET}"
    exit 1
fi

# Get the absolute path of the configuration directory
CONFIG_DIR_ABS=$(realpath "$CONFIG_DIR")

# Check if realpath command succeeded
if [ $? -ne 0 ]; then
    echo -e "${COLOR_DEBUG}[ERROR]${COLOR_RESET} Failed to resolve absolute path for: ${COLOR_PATH}$CONFIG_DIR${COLOR_RESET}"
    exit 1
fi

# Debug output for the absolute configuration directory
debug "CONFIG_DIR_ABS: ${COLOR_PATH}$CONFIG_DIR_ABS${COLOR_RESET}"

# Get the relative base path from the target directory
RELATIVE_BASE_PATH=$(realpath --relative-to="$TARGET_DIR" "$(dirname "$CONFIG_DIR_ABS")")

# Debug output for the relative base path
debug "RELATIVE_BASE_PATH: ${COLOR_PATH}$RELATIVE_BASE_PATH${COLOR_RESET}"

# Create the necessary directory structure command
mkdir_cmd="mkdir -p \"$PKGNAME/$RELATIVE_BASE_PATH\""
# Move the configuration directory command
mv_cmd="mv \"$CONFIG_DIR_ABS\" \"$PKGNAME/$RELATIVE_BASE_PATH/\""

# Debug output for the commands and variable values
debug "The following commands will be executed:"
debug "$(colorize_cmd "$mkdir_cmd")"
debug "$(colorize_cmd "$mv_cmd")"
debug "PKGNAME: ${COLOR_VAR}$PKGNAME${COLOR_RESET}"

# Prompt for final confirmation
confirm "The above commands will be executed. Do you want to proceed?"

# Execute the commands with error checking
execute_cmd "$mkdir_cmd" "Failed to create directory structure"
execute_cmd "$mv_cmd" "Failed to move configuration directory"

echo -e "${COLOR_DEBUG}[SUCCESS]${COLOR_RESET} Created package structure for ${COLOR_VAR}$PKGNAME${COLOR_RESET} and moved ${COLOR_PATH}$CONFIG_DIR${COLOR_RESET} to ${COLOR_PATH}$PKGNAME/$RELATIVE_BASE_PATH/${COLOR_RESET}"
