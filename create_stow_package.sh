#!/bin/bash

# ANSI color codes
COLOR_DEBUG='\033[1;36m'    # Cyan for [DEBUG]
COLOR_PATH='\033[1;33m'     # Yellow for file paths
COLOR_CMD='\033[1;35m'      # Magenta for commands
COLOR_VAR='\033[1;32m'      # Green for variable names/values
COLOR_ERROR='\033[1;31m'    # Red for errors
COLOR_SUCCESS='\033[1;32m'  # Green for success
COLOR_INFO='\033[1;34m'     # Blue for info
COLOR_RESET='\033[0m'       # Reset color

# Script options
VERBOSE=false
DRY_RUN=false

# Function definitions
print_separator() {
    echo -e "${COLOR_DEBUG}───────────────────────────────────────${COLOR_RESET}"
}

print_debug() {
    echo -e "${COLOR_DEBUG}[DEBUG]${COLOR_RESET} $1"
}

print_info() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"
}

print_error() {
    echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $1"
}

print_success() {
    echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} $1"
}

print_dryrun() {
    echo -e "${COLOR_INFO}[DRY-RUN]${COLOR_RESET} $1"
}

debug() {
    if [ "$VERBOSE" = true ]; then
        print_debug "$1"
    fi
}

print_usage() {
    cat << EOF
Usage: $(basename "$0") [-v] [-n] <pkgname> <config_dir>

Options:
    -v    Verbose mode (show additional debug information)
    -n    Dry-run mode (show commands without executing them)

Create a stow package structure from an existing configuration directory.

Arguments:
    pkgname    Name of the stow package to create
    config_dir Path to the existing configuration directory

Example:
    $(basename "$0") nvim ~/.config/nvim
    $(basename "$0") -n go ~/.config/go
EOF
    exit 1
}

cleanup() {
    echo -e "\n${COLOR_DEBUG}[INFO]${COLOR_RESET} Cleaning up..."
    # Remove partially created directory structure if it exists
    if [ -d "$PKGNAME" ]; then
        rm -rf "$PKGNAME"
    fi
    echo -e "${COLOR_DEBUG}[INFO]${COLOR_RESET} Operation cancelled by user"
    exit 1
}

check_dir() {
    local dir="$1"
    local msg="$2"
    if [ ! -d "$dir" ]; then
        print_error "$msg: ${COLOR_PATH}$dir${COLOR_RESET}"
        exit 1
    fi
}

create_backup() {
    local dir="$1"
    local backup_dir="${dir}.backup-$(date +%Y%m%d-%H%M%S)"
    if [ "$DRY_RUN" = true ]; then
        echo -e "${COLOR_DEBUG}[DRY-RUN]${COLOR_RESET} Would create backup: ${COLOR_PATH}$backup_dir${COLOR_RESET}"
        return 0
    fi
    if cp -r "$dir" "$backup_dir"; then
        echo -e "${COLOR_DEBUG}[INFO]${COLOR_RESET} Created backup: ${COLOR_PATH}$backup_dir${COLOR_RESET}"
        return 0
    fi
    return 1
}

confirm() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo    # Move to a new line
    # Default to 'n' if no input is provided
    REPLY=${REPLY:-n}
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${COLOR_DEBUG}[INFO]${COLOR_RESET} Operation cancelled by user."
        exit 1
    fi
}

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

colorize_cmd() {
    local cmd="$1"
    # First colorize the command name
    if [[ $cmd =~ ^(mkdir|mv) ]]; then
        cmd="${COLOR_CMD}${BASH_REMATCH[1]}${COLOR_RESET}${cmd:${#BASH_REMATCH[1]}}"
    fi
    # Then colorize the paths
    colorize_path "$cmd"
}

execute_cmd() {
    local cmd="$1"
    local error_msg="$2"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${COLOR_DEBUG}[DRY-RUN]${COLOR_RESET} Would execute: $(colorize_cmd "$cmd")"
        return 0
    fi
    
    if ! eval "$cmd"; then
        echo -e "${COLOR_DEBUG}[ERROR]${COLOR_RESET} $error_msg"
        exit 1
    fi
    debug "Executed: $(colorize_cmd "$cmd")"
}

# Main script execution starts here
# Set up trap
trap cleanup INT TERM

# Parse command line options
while getopts "vn" opt; do
    case $opt in
        v) VERBOSE=true ;;
        n) DRY_RUN=true ;;
        *) print_usage ;;
    esac
done
shift $((OPTIND-1))

# Update the argument check to use the usage function
if [ "$#" -lt 2 ]; then
    print_usage
fi

# Assign arguments to variables
PKGNAME="$1"
CONFIG_DIR="$2"

# Validate package name
if [[ ! "$PKGNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${COLOR_DEBUG}[ERROR]${COLOR_RESET} Invalid package name. Use only letters, numbers, underscores, and hyphens."
    exit 1
fi

# Read the target directory from .stowrc
TARGET_DIR=$(grep --no-messages '^--target=' .stowrc | cut -d'=' -f2)

# Expand the TARGET_DIR variable to its actual path
TARGET_DIR=$(eval echo "$TARGET_DIR")

# Check if the target directory was found
if [ -z "$TARGET_DIR" ]; then
    echo "Target directory not found in .stowrc"
    exit 1
fi

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

# Get the relative base path from the target directory
RELATIVE_BASE_PATH=$(realpath --relative-to="$TARGET_DIR" "$(dirname "$CONFIG_DIR_ABS")")

# Create the necessary directory structure command
mkdir_cmd="mkdir -p \"$PKGNAME/$RELATIVE_BASE_PATH\""
# Move the configuration directory command
mv_cmd="mv \"$CONFIG_DIR_ABS\" \"$PKGNAME/$RELATIVE_BASE_PATH/\""

# Update the debug and summary section
print_separator
print_info "Summary of operations:"
echo -e "  • Package name: ${COLOR_VAR}$PKGNAME${COLOR_RESET}"
echo -e "  • Source: ${COLOR_PATH}$CONFIG_DIR_ABS${COLOR_RESET}"
echo -e "  • Destination: ${COLOR_PATH}$PKGNAME/$RELATIVE_BASE_PATH/${COLOR_RESET}"
print_separator

# Always show commands that will be executed
echo -e "${COLOR_DEBUG}[INFO]${COLOR_RESET} Commands to be executed:"
echo -e "  • $(colorize_cmd "$mkdir_cmd")"
echo -e "  • $(colorize_cmd "$mv_cmd")"

# Show technical details only in verbose mode
if [ "$VERBOSE" = true ]; then
    print_separator
    echo -e "${COLOR_DEBUG}[DEBUG]${COLOR_RESET} Technical Details:"
    echo -e "  • TARGET_DIR: ${COLOR_VAR}$TARGET_DIR${COLOR_RESET}"
    echo -e "  • CONFIG_DIR_ABS: ${COLOR_PATH}$CONFIG_DIR_ABS${COLOR_RESET}"
    echo -e "  • RELATIVE_BASE_PATH: ${COLOR_PATH}$RELATIVE_BASE_PATH${COLOR_RESET}"
fi

print_separator
echo -e "${COLOR_DEBUG}[INFO]${COLOR_RESET} Ready to proceed with the above operations."

# Prompt for final confirmation
confirm

# Add before moving the configuration directory
# Create backup of the configuration directory
create_backup "$CONFIG_DIR_ABS" || {
    echo -e "${COLOR_DEBUG}[ERROR]${COLOR_RESET} Failed to create backup"
    exit 1
}

# Execute the commands with error checking
execute_cmd "$mkdir_cmd" "Failed to create directory structure"
execute_cmd "$mv_cmd" "Failed to move configuration directory"

# Update the success message to respect dry-run mode
if [ "$DRY_RUN" = false ]; then
    print_success "Created package structure for ${COLOR_VAR}$PKGNAME${COLOR_RESET} and moved ${COLOR_PATH}$CONFIG_DIR${COLOR_RESET} to ${COLOR_PATH}$PKGNAME/$RELATIVE_BASE_PATH/${COLOR_RESET}"
else
    print_dryrun "Would create package structure for ${COLOR_VAR}$PKGNAME${COLOR_RESET}"
fi
