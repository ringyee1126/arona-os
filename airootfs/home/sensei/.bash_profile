export PATH="$HOME/.local/bin:$PATH"   # claude (Claude Code)
[[ -f ~/.bashrc ]] && . ~/.bashrc
if [[ -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]]; then
  if command -v start-hyprland >/dev/null; then exec start-hyprland; else exec Hyprland; fi
fi
