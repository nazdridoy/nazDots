# ── XDG Base Directories ─────────────────────────────────────────────
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

# ── Default Applications ─────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
export SUDO_EDITOR='nvim'
export BROWSER='brave'

# ── SSH ──────────────────────────────────────────────────────────────
export SSH_ASKPASS=/usr/bin/ksshaskpass
export SSH_ASKPASS_REQUIRE=prefer
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"

# ── ZSH / Oh-My-Zsh ─────────────────────────────────────────────────
export ZDOTDIR="$HOME/.config/zsh"
export ZSH="$XDG_DATA_HOME/oh-my-zsh"
export ZSH_CUSTOM="$XDG_DATA_HOME/oh-my-zsh/custom"

# ── Input Method (IBus) ─────────────────────────────────────────────
#export GTK_IM_MODULE=ibus
#export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export GLFW_IM_MODULE=ibus

# ── KDE / Qt ─────────────────────────────────────────────────────────
# Silence non-critical KDE/Qt framework warnings in the terminal.
# Hides "empty domain" (kf.i18n) and "missing platform plugin" (kf.windowsystem)
# messages often triggered by CLI tools like kwalletcli.
export QT_LOGGING_RULES="kf.i18n.warning=false;kf.windowsystem.warning=false"
export KDEHOME="$XDG_CONFIG_HOME/kde"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export XCURSOR_PATH="/usr/share/icons:$XDG_DATA_HOME/icons"

# ── Virtualisation ───────────────────────────────────────────────────
# Force virsh to use the System instance (root) instead of the User session.
# Allows managing VMs in /var/lib/libvirt/images without sudo.
export LIBVIRT_DEFAULT_URI="qemu:///system"

# ── XDG Compliance Overrides ─────────────────────────────────────────
# Android
export ANDROID_USER_HOME="$XDG_DATA_HOME/android"
export ANDROID_HOME="$XDG_DATA_HOME/android"
# Rust
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
# Go
export GOPATH="$XDG_DATA_HOME/go"
# Node.js
export NVM_DIR="$XDG_DATA_HOME/nvm"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
# Python
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
export PYTHON_HISTORY="$XDG_CONFIG_HOME/python/python_history"
export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
# Java
export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
# GDB
export GDBHISTFILE="$XDG_CONFIG_HOME/gdb/.gdb_history"
# NVIDIA
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
# Less
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"
# SQLite
export SQLITE_HISTORY="$XDG_CACHE_HOME/sqlite_history"
# DVD / Wine / Unison
export DVDCSS_CACHE="$XDG_DATA_HOME/dvdcss"
export WINEPREFIX="$XDG_DATA_HOME/wine"
export UNISON="$XDG_DATA_HOME/unison"
# DistroBox
export DBX_CONTAINER_CUSTOM_HOME="$XDG_DATA_HOME/DistroBox_CUSTOM_HOME"
# Radare2
export R2ENV_PATH="$XDG_DATA_HOME/r2env"
# GNU Parallel
export PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"
# PlatformIO
export PLATFORMIO_CORE_DIR="$XDG_DATA_HOME/platformio"
# w3m
export W3M_DIR="$XDG_DATA_HOME/w3m"

# ── Custom API Endpoints ─────────────────────────────────────────────
export HF_BASE="http://scw.nazdev.tech:11155"

# ── PATH ─────────────────────────────────────────────────────────────
[ -d "$HOME/.bin" ]       && PATH="$HOME/.bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

export PATH="$PATH:$XDG_DATA_HOME/soar/bin"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$CARGO_HOME/bin"
export PATH="$PATH:$R2ENV_PATH/bin"
export PATH="$PATH:$HOME/.luarocks/bin"
#export PATH="$PATH:$XDG_DATA_HOME/npm/bin"

# export perl local::lib PATH
# eval $(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)
