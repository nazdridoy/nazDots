# XDG ENV Variables
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

# Preferred editor for local and remote sessions
export EDITOR='nvim'
export VISUAL='nvim'
# Use Neovim when running sudoedit
export SUDO_EDITOR='nvim'

# Default Browser
export BROWSER='brave'

# SSH GUI Askpass
export SSH_ASKPASS=/usr/bin/ksshaskpass
export SSH_ASKPASS_REQUIRE=prefer
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"

# Silence non-critical KDE/Qt framework warnings in the terminal.
# Specifically hides "empty domain" (kf.i18n) and "missing platform plugin" (kf.windowsystem) 
# messages often triggered by CLI tools like kwalletcli.
export QT_LOGGING_RULES="kf.i18n.warning=false;kf.windowsystem.warning=false"

# Ibus KDE
#export GTK_IM_MODULE=ibus
#export QT_IM_MODULE=ibus
#export XMODIFIERS=@im=ibus
export GLFW_IM_MODULE=ibus


# Export local PATH
if [ -d "$HOME/.bin" ] ;
  then PATH="$HOME/.bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ] ;
  then PATH="$HOME/.local/bin:$PATH"
fi

# ZSH ENV Variables
export ZDOTDIR=$HOME/.config/zsh
export ZSH="$XDG_DATA_HOME/oh-my-zsh"
export ZSH_CUSTOM=$XDG_DATA_HOME/oh-my-zsh/custom
# Android ENV Variables
export ANDROID_USER_HOME="$XDG_DATA_HOME"/android
export ANDROID_HOME="$XDG_DATA_HOME"/android
# Rust ENV Variables
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
# NVIDIA ENV Variables
export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv
# LESS ENV Variables
export LESSHISTFILE="$XDG_CACHE_HOME"/less/history
# DVD ENV Variables
export DVDCSS_CACHE="$XDG_DATA_HOME"/dvdcss
# UNISON ENV Variables
export UNISON="$XDG_DATA_HOME"/unison
# Wine ENV Variables
export WINEPREFIX="$XDG_DATA_HOME"/wine
# Python ENV Variables
export PYTHONSTARTUP="$XDG_CONFIG_HOME"/python/pythonrc
export PYTHON_HISTORY="$XDG_CONFIG_HOME"/python/python_history
# Java ENV Variables
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
# KDE ENV Variables
export KDEHOME="$XDG_CONFIG_HOME"/kde
# DistroBox ENV Variables
export DBX_CONTAINER_CUSTOM_HOME="$XDG_DATA_HOME"/DistroBox_CUSTOM_HOME
# SQLITE ENV Variables
export SQLITE_HISTORY="$XDG_CACHE_HOME"/sqlite_history
# Node.js ENV Variables
export NVM_DIR="$XDG_DATA_HOME"/nvm
export NODE_REPL_HISTORY="$XDG_DATA_HOME"/node_repl_history
# Go ENV Variables
export GOPATH="$XDG_DATA_HOME"/go
# R2 ENV Variables
export R2ENV_PATH="$XDG_DATA_HOME"/r2env
# Parallel ENV Variables
export PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel
# export SOAR package manager bin PATH
export PATH=$PATH:"$XDG_DATA_HOME"/soar/bin

# export GO PATH
export PATH=$PATH:"$XDG_DATA_HOME"/go/bin
# export Cargo PATH
export PATH=$PATH:/home/nazmul/.local/share/cargo/bin
# export radare2 PATH
export PATH=$PATH:/home/nazmul/.local/share/r2env/bin 
# export npm PATH
#export PATH=$PATH:/home/nazmul/.local/share/npm/bin
# export luarocks PATH
export PATH="$PATH:$HOME/.luarocks/bin"

# export perl local::db PATH
# eval $(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)

# w3m browser data
export W3M_DIR="$XDG_DATA_HOME"/w3m
# platformio
export PLATFORMIO_CORE_DIR="$XDG_DATA_HOME"/platformio
# GDB Env
export GDBHISTFILE="$XDG_CONFIG_HOME"/gdb/.gdb_history
# GTK2 RC FILES
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc  
# pyenv Env
export PYENV_ROOT="$XDG_DATA_HOME"/pyenv 

# HF-Inferoxy Base URL
export HF_BASE="http://scw.nazdev.tech:11155" 
