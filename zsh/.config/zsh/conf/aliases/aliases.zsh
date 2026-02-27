# ── Core Defaults ────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias df='df -h'                                                  # human-readable sizes
alias free='free -mt'                                               # MB + total row
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts" --continue' # XDG-compliant + resume
alias rg='rg --sort path'                                           # ripgrep sorted by path

# ── File Listing (eza) ───────────────────────────────────────────────
eza_params=('--git' '--icons' '--classify' '--group-directories-first' '--time-style=long-iso' '--group' '--color-scale' 'all')

alias ls='ls --hyperlink --color=auto'
alias l='eza --hyperlink ${eza_params}'                             # short listing
alias ll='eza --hyperlink --all --header --long ${eza_params}'      # long listing (all files)
alias llm='eza --hyperlink --all --header --long --sort=modified ${eza_params}'  # long, sorted by modified
alias la='eza --hyperlink -lbhHigUmuSa'                             # long with all metadata
alias lx='eza --hyperlink -lbhHigUmuSa@'                            # long with extended attrs
alias lt='eza --hyperlink --tree --long'                            # tree view

# ── Package Management (pacman / paru) ──────────────────────────────
alias pacman='sudo pacman --color auto'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'                    # remove orphaned packages
alias unlock='sudo rm /var/lib/pacman/db.lck'                       # remove pacman db lock
alias list='sudo pacman -Qqe'                                       # list explicitly installed
alias listt='sudo pacman -Qqet'                                     # list explicit, no deps
alias listaur='sudo pacman -Qqem'                                   # list AUR packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"      # recent installs (200)
alias riplong="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -3000 | nl" # recent installs (3000)
alias paruskip='paru -S --mflags --skipinteg'                       # install, skip integrity check
alias yayskip='yay -S --mflags --skipinteg'                         # install, skip integrity check
alias trizenskip='trizen -S --skipinteg'                            # install, skip integrity check

# depends <pkg> — list packages that depend on <pkg>
function_depends() {
    search=$(echo "$1")
    sudo pacman -Sii $search | grep "Required" | sed -e "s/Required By     : //g" | sed -e "s/  /\n/g"
}
alias depends='function_depends'

# Paru helpers (only if paru is available)
if (( $+commands[paru] )); then
  # Updates
  alias paupg='paru -Syu'              # full system upgrade
  alias pasu='paru -Syu --noconfirm'   # non-interactive upgrade
  alias paupd='paru -Sy'               # sync package databases
  alias upgrade='paru -Syu'            # alias for paupg
  alias pamir='paru -Syy'              # force-refresh package lists
  # Install / Remove
  alias pain='paru -S'                 # install package
  alias pains='paru -U'                # install from local file
  alias pare='paru -R'                 # remove package
  alias parem='paru -Rns'              # remove with deps & configs
  # Queries
  alias parep='paru -Si'               # remote package info
  alias pareps='paru -Ss'              # search remote repos
  alias paloc='paru -Qi'               # local package info
  alias palocs='paru -Qs'              # search local packages
  alias palst='paru -Qe'               # list explicitly installed
  # Cleanup
  alias paclean='paru -Sc'             # clean package cache
  alias paclr='paru -Scc'              # clean ALL cached files
  alias paorph='paru -Qtd'             # list orphaned packages
  alias painsd='paru -S --asdeps'      # install as dependency
fi

# ── Mirrors ──────────────────────────────────────────────────────────
alias mirror='sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist'         # fastest 30
alias mirrord='sudo reflector --latest 30 --number 10 --sort delay --save /etc/pacman.d/mirrorlist'     # sort by delay
alias mirrors='sudo reflector --latest 30 --number 10 --sort score --save /etc/pacman.d/mirrorlist'     # sort by score
alias mirrora='sudo reflector --latest 30 --number 10 --sort age --save /etc/pacman.d/mirrorlist'       # sort by age
alias mirrorx='sudo reflector --age 6 --latest 20 --fastest 20 --threads 5 --sort rate --protocol https --save /etc/pacman.d/mirrorlist'    # best HTTPS (5 threads)
alias mirrorxx='sudo reflector --age 6 --latest 20 --fastest 20 --threads 20 --sort rate --protocol https --save /etc/pacman.d/mirrorlist'  # best HTTPS (20 threads)
alias ram='rate-mirrors --allow-root --disable-comments arch | sudo tee /etc/pacman.d/mirrorlist'        # rate-mirrors (any protocol)
alias rams='rate-mirrors --allow-root --disable-comments --protocol https arch | sudo tee /etc/pacman.d/mirrorlist' # rate-mirrors (HTTPS only)

# ── System Administration ────────────────────────────────────────────
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'       # regenerate grub config
alias update-fc='sudo fc-cache -fv'                                 # rebuild font cache
alias fix-permissions='sudo chown -R $USER:$USER ~/.config ~/.local' # fix ownership on dotfiles
alias ssn='sudo shutdown now'                                       # shutdown immediately
alias sr='reboot'                                                   # reboot
alias sysfailed='systemctl list-units --failed'                     # list failed systemd units
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"    # set default shell to ZSH

# ── Quick Config Editors ─────────────────────────────────────────────
alias npacman="sudo $EDITOR /etc/pacman.conf"
alias ngrub="sudo $EDITOR /etc/default/grub"
alias nconfgrub="sudo $EDITOR /boot/grub/grub.cfg"
alias nmkinitcpio="sudo $EDITOR /etc/mkinitcpio.conf"
alias nmirrorlist="sudo $EDITOR /etc/pacman.d/mirrorlist"
alias nsddm="sudo $EDITOR /etc/sddm.conf"
alias nsddmk="sudo $EDITOR /etc/sddm.conf.d/kde_settings.conf"
alias nfstab="sudo $EDITOR /etc/fstab"
alias nnsswitch="sudo $EDITOR /etc/nsswitch.conf"
alias nsamba="sudo $EDITOR /etc/samba/smb.conf"
alias ngnupgconf="sudo $EDITOR /etc/pacman.d/gnupg/gpg.conf"
alias nhosts="sudo $EDITOR /etc/hosts"
alias nhostname="sudo $EDITOR /etc/hostname"
alias nresolv="sudo $EDITOR /etc/resolv.conf"
alias nz="$EDITOR ~/.zshrc"
alias nvconsole="sudo $EDITOR /etc/vconsole.conf"
alias nenvironment="sudo $EDITOR /etc/environment"

# ── Log Readers ──────────────────────────────────────────────────────
alias jctl='journalctl -p 3 -xb'        # errors from current boot
alias lpacman='bat /var/log/pacman.log'  # view pacman log
alias lxorg='bat /var/log/Xorg.0.log'    # view Xorg log
alias lxorgo='bat /var/log/Xorg.0.log.old' # view previous Xorg log

# ── bat Aliases ──────────────────────────────────────────────────────
alias bathelp='bat --plain --language=help'  # prettify --help output
alias batlog='bat --paging=never -l log'     # prettify log files
alias batdiff='bat --diff'                   # show git diff in bat
alias batshow='bat --show-all'               # show non-printable chars

# ── Git ──────────────────────────────────────────────────────────────
alias grh='git reset --hard'         # hard reset to HEAD
alias rmgitcache='rm -r ~/.cache/git' # purge git cache

# ── GPG ──────────────────────────────────────────────────────────────
alias gpg-check='gpg2 --keyserver-options auto-key-retrieve --verify'       # verify a signature
alias gpg-retrieve='gpg2 --keyserver-options auto-key-retrieve --receive-keys' # fetch a dev's key
alias fix-keyserver="[ -d ~/.gnupg ] || mkdir ~/.gnupg ; cp /etc/pacman.d/gnupg/gpg.conf ~/.gnupg/ ; echo 'done'" # bootstrap gpg.conf

# ── System Info ──────────────────────────────────────────────────────
alias hw='hwinfo --short'                                          # compact hardware info
alias audio="pactl info | grep 'Server Name'"                      # show audio server (pulse/pipewire)
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'  # check CPU vulnerabilities
alias cpu="cpuid -i | grep uarch | head -n 1"                      # show CPU micro-architecture
alias big="expac -H M '%m\t%n' | sort -h | nl"                     # largest installed packages
alias userlist="cut -d: -f1 /etc/passwd | sort"                    # list all system users

# ── Process Management ───────────────────────────────────────────────
alias psa='ps auxf'                                                # process tree
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"          # search running processes

# ── yt-dlp ───────────────────────────────────────────────────────────
alias yta-aac='yt-dlp --extract-audio --audio-format aac'           # download audio as AAC
alias yta-best='yt-dlp --extract-audio --audio-format best'         # download best audio
alias yta-flac='yt-dlp --extract-audio --audio-format flac'         # download audio as FLAC
alias yta-mp3='yt-dlp --extract-audio --audio-format mp3'           # download audio as MP3
alias ytv-best="yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4" # download best video as MP4

# ── XDG Compliance Wrappers ─────────────────────────────────────────
alias yarn='yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"'                # keep yarn config in XDG
alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"' # keep nvidia config in XDG
alias svn="svn --config-dir $XDG_CONFIG_HOME/subversion"                     # keep svn config in XDG
alias adb='HOME="$XDG_DATA_HOME"/android adb'                                # keep adb data in XDG

# ── Network & VPN Bypass ─────────────────────────────────────────────
alias b2i='BIND_INTERFACE=wlan0 DNS_OVERRIDE_IP=8.8.8.8 LD_PRELOAD=/usr/lib/bindToInterface.so'        # bind next cmd to wlan0 (bypass VPN)
alias novpn='BIND_INTERFACE=enp0s20f0u1u2c2 DNS_OVERRIDE_IP=8.8.8.8 LD_PRELOAD=/usr/lib/bindToInterface.so' # bind next cmd to USB ethernet (bypass VPN)
alias connect_phone='env PHONE=192.168.0.102 bash -c '\''HOME="$XDG_DATA_HOME"/android adb connect ${PHONE}:$(nmap -sT ${PHONE} -p30000-49999 | awk -F/ "/tcp open/{print \$1}")'\''' # adb connect to phone via Wi-Fi (auto-detect port)

# ── Application Shortcuts ────────────────────────────────────────────
alias vim='nvim'                  # always use Neovim
alias slife='prime-run firestorm'  # run Second Life (Firestorm) on dGPU
alias mnlx='BROWSER=lynx man -H'   # view man pages as HTML in lynx

# ── Secrets (KDE Wallet) ─────────────────────────────────────────────
alias set-admin-key='export ADMIN_API_KEY=$(kwallet-query --folder "hf-inferoxy-api" --read-password "ADMIN_API_KEY" kdewallet)' # load admin key from KDE Wallet
alias set-hf-token='export HF_TOKEN=$(kwallet-query --folder "hf-inferoxy-api" --read-password "HF_TOKEN" kdewallet)'            # load HF token from KDE Wallet

# ── Privacy ──────────────────────────────────────────────────────────
alias unhblock='hblock -S none -D none' # disable hblock ad/tracker blocking

# ── Utilities ────────────────────────────────────────────────────────
alias path='echo -e ${PATH//:/\\n}'        # print PATH entries, one per line
alias merge='xrdb -merge ~/.Xresources' # reload Xresources settings