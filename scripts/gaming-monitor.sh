#!/usr/bin/env bash

DISPLAY_MODE=$1
CONFIG="$HOME/.config/hypr/UserConfigs/WindowRules.conf"


# Remove existing game workspace rules
sed -i -E "/windowrulev2 = workspace (8|9), tag:games\*/d" "$CONFIG"

if [[ "$DISPLAY_MODE" == "tv" ]]; then
	echo "Configuring for TV (HDMI-A-1)"
	echo "windowrulev2 = workspace 9, tag:games*" >> "$CONFIG"
	
	echo "Set TV (HDMI-A-1) as primary"
	xrandr --output HDMI-A-1 --primary
  
else
    echo "Configuring for TV (DP-3)"
    echo "windowrulev2 = workspace 8, tag:games*" >> "$CONFIG"

    echo "Set TV (DP-3) as primary"
	xrandr --output DP-3 --primary
fi

# Reload Hyprland configuration
hyprctl reload
