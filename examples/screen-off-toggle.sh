#!/usr/bin/env bash
# Example implementation of the screen-off action that POST /screen-off runs
# (via `systemctl --user start screen-off-toggle.service`).
#
# The server does not ship this: turning displays off and silencing
# notifications is desktop-specific. Copy it, edit if needed, install both this
# and the unit next to it:
#
#   install -m755 examples/screen-off-toggle.sh ~/.local/bin/screen-off-toggle
#   install -m644 examples/screen-off-toggle.service ~/.config/systemd/user/
#   systemctl --user daemon-reload
#
# Picks a method automatically. Add your own branch if none of these fit.
set -euo pipefail

# Optional: also enable Do Not Disturb on KDE Plasma while the screens are off.
DND="${SCREEN_OFF_DND:-1}"

kde_dnd_on() {
    [[ "$DND" == "1" ]] || return 0
    command -v kwriteconfig6 >/dev/null 2>&1 || return 0
    kwriteconfig6 --file plasmanotifyrc --group DoNotDisturb --key Until \
        "$(date -u -d '+8 hours' +%Y-%m-%dT%H:%M:%SZ)" 2>/dev/null || true
}

if command -v loginctl >/dev/null 2>&1 && [[ -n "${XDG_SESSION_ID:-}" ]]; then
    # Works on any logind session, Wayland or X11.
    kde_dnd_on
    exec loginctl lock-session "$XDG_SESSION_ID"
fi

if [[ "${XDG_SESSION_TYPE:-}" == "x11" ]] && command -v xset >/dev/null 2>&1; then
    kde_dnd_on
    exec xset dpms force off
fi

if command -v swaymsg >/dev/null 2>&1; then
    exec swaymsg 'output * power off'
fi

if command -v hyprctl >/dev/null 2>&1; then
    exec hyprctl dispatch dpms off
fi

echo "screen-off-toggle: no supported method found (tried loginctl, xset, swaymsg, hyprctl)" >&2
exit 1
