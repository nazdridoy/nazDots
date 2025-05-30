# System utility functions

# Open scripts by its name
nvis () {
  nvim $(which $1)
}

# Create a directory and change into it at the same time
mkd() {
  # Add error handling and feedback
  if [[ $# -eq 0 ]]; then
    echo "Usage: mkd <directory_name> [directory_name2 ...]"
    return 1
  fi
  
  mkdir -p "$@"
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create directory"
    return 1
  fi
  
  if [[ "$#" -gt 1 ]]; then
    echo "Multiple directories created. Select one to enter:"
    selected_dir=$(echo "$@" | tr ' ' '\n' | fzf)
    [[ -n "$selected_dir" ]] && cd "$selected_dir" && pwd
  else
    cd "$1" && pwd
  fi
}

# Function for Compiling Plugins to byte code 
function plugin-compile {
  # Handle help flags
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: plugin-compile [-v]"
    echo ""
    echo "Compile zsh plugins and configuration files to byte code for faster loading"
    echo ""
    echo "Options:"
    echo "  -v    Verbose mode - show detailed compilation progress"
    echo "  -h    Show this help message"
    echo ""
    echo "Directories processed:"
    echo "  - \$ZSH_CUSTOM     (Custom plugins and themes)"
    echo "  - \$ZSH/plugins    (Oh-My-Zsh plugins)"
    echo "  - \$ZSH/lib        (Oh-My-Zsh library files)"
    echo "  - \$ZDOTDIR/conf   (User configuration files)"
    echo ""
    echo "Example:"
    echo "  plugin-compile     # Quiet compilation"
    echo "  plugin-compile -v  # Show compilation details"
    return 0
  fi

  # Add error handling
  local dirs=(
    "$ZSH_CUSTOM"
    "$ZSH/plugins"
    "$ZSH/lib"
    "$ZDOTDIR/conf"
  )
  
  local verbose=false
  if [[ "$1" == "-v" ]]; then
    verbose=true
    shift
  fi
  
  autoload -U zrecompile
  
  # Check if directories exist
  for dir in $dirs; do
    if [[ ! -d "$dir" ]]; then
      echo "Warning: Directory $dir does not exist"
      continue
    fi
    
    echo "Compiling files in $dir..."
    for file in "$dir"/**/*.zsh{,-theme}(N); do
      if $verbose; then
        echo "Compiling: $file"
        zrecompile -p "$file"
      else
        zrecompile -pq "$file"
      fi
    done
  done
  
  echo "Plugin compilation complete!"
}

# Advanced webcam manager to enable/disable specific or all webcams
webcam-manager() {
  # Check if required tools are available
  if ! command -v v4l2-ctl &> /dev/null; then
    echo "Error: v4l2-ctl not found. Please install v4l2-utils package."
    return 1
  fi
  
  if ! command -v fzf &> /dev/null; then
    echo "Error: fzf not found. Please install fzf package."
    return 1
  fi

  # Function to check if webcam module is loaded
  webcam_status() {
    if lsmod | grep -q "uvcvideo"; then
      print -P "%F{green}ENABLED%f"
      return 0
    else
      print -P "%F{red}DISABLED%f"
      return 1
    fi
  }

  # Function to check if a device is accessible (has read/write permissions)
  device_accessible() {
    local device=$1
    if [[ -r "$device" && -w "$device" ]]; then
      return 0
    else
      return 1
    fi
  }

  # Function to list all webcam devices
  list_webcams() {
    echo "Detected webcam devices:"
    if webcam_status >/dev/null; then
      local devices=$(v4l2-ctl --list-devices 2>/dev/null)
      if [[ -z "$devices" ]]; then
        echo "No accessible webcam devices found, but module is loaded."
        echo "Some devices may be disabled (check permissions below)."
      else
        echo "$devices"
      fi
      
      echo "\nVideo device nodes and permissions:"
      ls -la /dev/video* 2>/dev/null || echo "No video nodes available"
      
      # Try to show device info even for disabled devices
      for device in /dev/video*; do
        if [[ -e "$device" ]]; then
          local dev_name=$(basename "$device")
          if device_accessible "$device"; then
            local info=$(v4l2-ctl --device=$device --info 2>/dev/null | grep "Card type" | cut -d: -f2- | xargs)
            echo -n "$dev_name: "
            if [[ -n "$info" ]]; then
              print -P "%F{green}ENABLED%f - $info"
            else
              print -P "%F{green}ENABLED%f - Unknown device"
            fi
          else
            echo -n "$dev_name: "
            print -P "%F{red}DISABLED%f - No access permissions"
          fi
        fi
      done
    else
      echo "Cannot list devices - webcam module is not loaded."
    fi
  }

  # Show initial status
  echo "===== WEBCAM MANAGER ====="
  echo -n "Webcam module status: "
  webcam_status
  echo ""
  list_webcams
  echo ""

  # Prepare menu options
  local options=()
  
  # Module level options
  if lsmod | grep -q "uvcvideo"; then
    options+=("disable_all|Disable all webcam devices (unload module)")
  else
    options+=("enable_all|Enable all webcam devices (load module)")
  fi
  
  # Device specific options
  if lsmod | grep -q "uvcvideo"; then
    for device in /dev/video*; do
      if [[ -e "$device" ]]; then
        local dev_name=$(basename "$device")
        if device_accessible "$device"; then
          # Device is accessible, offer disable option
          local card_info=$(v4l2-ctl --device=$device --info 2>/dev/null | grep "Card type" | cut -d: -f2- | xargs)
          if [[ -n "$card_info" ]]; then
            options+=("disable_device|$dev_name|Disable $dev_name ($card_info)")
          else
            options+=("disable_device|$dev_name|Disable $dev_name")
          fi
        else
          # Device exists but not accessible, offer enable option
          options+=("enable_device|$dev_name|Enable $dev_name")
        fi
      fi
    done
  fi
  
  # Add exit option
  options+=("exit|Exit webcam manager")

  # Show menu with fzf
  local selection=$(printf "%s\n" "${options[@]}" | column -t -s"|" | fzf --prompt="Select action: " --height=~50%)
  
  # Exit if no selection was made
  [[ -z "$selection" ]] && { echo "No action selected. Exiting."; return 0; }
  
  # Extract action from selection
  local action=$(echo "$selection" | awk '{print $1}')
  local device=$(echo "$selection" | grep -o "video[0-9]*" | head -1)
  
  # Process selection
  case "$action" in
    enable_all)
      echo "Enabling webcam module..."
      sudo modprobe uvcvideo
      sleep 1
      # Also restore permissions on all devices
      for dev in /dev/video*; do
        if [[ -e "$dev" ]]; then
          sudo chmod 660 "$dev"
        fi
      done
      echo ""
      echo -n "Webcam module status: "
      webcam_status
      echo ""
      list_webcams
      ;;
    disable_all)
      echo "Disabling webcam module..."
      sudo modprobe -r uvcvideo
      sleep 1
      echo ""
      echo -n "Webcam module status: "
      webcam_status
      ;;
    enable_device)
      if [[ -e "/dev/$device" ]]; then
        echo "Enabling device $device..."
        sudo chmod 660 "/dev/$device"
        echo "Device $device enabled. Access permissions restored."
      else
        echo "Error: Device /dev/$device not found"
      fi
      echo ""
      list_webcams
      ;;
    disable_device)
      if [[ -e "/dev/$device" ]]; then
        echo "Disabling device $device..."
        sudo chmod 000 "/dev/$device"
        echo "Device $device disabled. Access permissions removed."
      else
        echo "Error: Device /dev/$device not found"
      fi
      echo ""
      list_webcams
      ;;
    exit|"")
      echo "Exiting webcam manager"
      return 0
      ;;
    *)
      echo "Invalid selection"
      return 1
      ;;
  esac
  
  echo "\nWebcam manager operation completed."
} 