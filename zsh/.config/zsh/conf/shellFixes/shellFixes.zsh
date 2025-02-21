## Fix Cursor Terminal ZSH ENV issue

if [[ "$ARGV0" == "/opt/cursor-bin/cursor-bin.AppImage" ]]; then
  unset ARGV0
fi
