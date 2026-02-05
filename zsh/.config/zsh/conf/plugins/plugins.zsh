########################################################
#####               Plugin Settings                #####
########################################################
repos=(
  # plugins that you want loaded first
  

  # other plugins
  zsh-users/zsh-completions # Additional completion definitions for Zsh.
  Aloxaf/fzf-tab # Tab complition fn1/fn2 to switch group
  hlissner/zsh-autopair #auto pair {},(),[]...

  # plugins you want loaded last
  z-shell/F-Sy-H #Feature-rich Syntax Highlighting for Zsh

)

# Array to keep track of installed plugins
installed_plugins=()

for repo in $repos; do
  plugin_name=${repo:t}
  plugin_path=$ZSH_CUSTOM/plugins/$plugin_name

  if [[ ! -d $plugin_path ]]; then
    git clone https://github.com/$repo $plugin_path
  fi

  installed_plugins+=($plugin_name)
done

# Remove plugins that are not present in the repos array
for plugin in $ZSH_CUSTOM/plugins/*(/); do
  plugin_name=${plugin:t}
  if [[ -z ${installed_plugins[(r)$plugin_name]} && $plugin_name != "example" ]]; then
    #fix omz update git marge issue
    rm -rf $plugin
  fi
done

unset repo{s,} plugin_name plugin_path installed_plugins


# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
git
#colored-man-pages
bgnotify # Background notifications for long running commands

fzf #enables fuzzy auto-completion and key bindings.
fzf-tab
aliases
fancy-ctrl-z #Use Ctrl-Z to switch back to Vim
command-not-found
zsh-autopair


F-Sy-H ##For syntax highlighting
#history-substring-search

)

########################################################
#####            Extra plugin (source)             #####
########################################################

# Load zsh-users/zsh-completions
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

########################################################
#####              Plugins Settings                #####
########################################################

# Fzf-tab

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group 'left' 'right'
# disable sort when completing options of any command
zstyle ':completion:complete:*:options' sort false
# Specify the fuzzy search program tmux
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

########################################################
#####               Plugins Exports                #####
########################################################

export _Z_DATA="$XDG_DATA_HOME/z"

# zsh-fzf key bindings 

export FZF_TMUX_OPTS="--tmux --height=80%"

export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
# For rg: export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git/*'"
# For ag: export FZF_DEFAULT_COMMAND="ag -g '' --hidden --ignore .git"

# CTRL+T to list files and directories
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers,changes --color=always {}' --preview-window=up:60%:wrap --height=80%"

# CTRL+R reverse search through command history
# export FZF_CTRL_R_OPTS="--preview 'less {}' --preview-window=up:60%:wrap --height=80%"
# CTRL-/ to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard, ctrl-/ to toggle-preview'"

# ALT+C  fuzzy directory change
export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git"
# For rg: export FZF_ALT_C_COMMAND="rg --directories --hidden --glob '!.git/*'"
# For ag: export FZF_ALT_C_COMMAND="ag -g '' --hidden --ignore .git --depth 1"
export FZF_ALT_C_OPTS="--preview 'exa --color=always --tree --level=2 {}' --preview-window=up:60%:wrap --height=80%"

#zoxide disable Print the matched directory before navigating to it 
export _ZO_ECHO='0'
# fzf Use ~~ as the trigger sequence instead of the default **
export FZF_COMPLETION_TRIGGER='~~'
