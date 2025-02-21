########################################################
#####             ZSH Global Settings              #####
########################################################

# History
HISTFILE=~/.config/zsh/.zsh_history
setopt HIST_IGNORE_DUPS
HISTSIZE='128000'
SAVEHIST='128000'

# Defaulf Browser ENV Variable
# export BROWSER=brave
# Make Neovim the default editor
# export VISUAL='nvim'
# export EDITOR=$VISUAL
# export SUDO_EDITOR=$VISUAL
# Use most instade of less
export PAGER=less

# ZSH Options
setopt -J4 #DOC- 'https://zsh.sourceforge.io/Doc/Release/Options.html'
unsetopt SHARE_HISTORY
#setopt SHARE_HISTORY
