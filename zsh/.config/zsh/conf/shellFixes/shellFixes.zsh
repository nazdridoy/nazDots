## Fix Cursor Terminal ZSH ENV issue

if [[ "$ARGV0" == *cursor* && "$ARGV0" == *AppImage* ]]; then
  unset ARGV0
fi
