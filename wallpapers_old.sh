#!/usr/bin/env bash

#random wallpaper selector
NEW_WP=$(ls $HOME/Images/Wallpapers | shuf -n 1)

# Wallpapers Repository Path
WALLPAPER="$HOME/Images/Wallpapers/$NEW_WP"

# hyprpaper.conf path
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# clear hyprpaper.conf
echo " " > $HYPRPAPER_CONF

# Change hyprpaper.conf
echo "preload = $WALLPAPER" >> $HYPRPAPER_CONF
echo "wallpaper = ,$WALLPAPER" >> $HYPRPAPER_CONF
echo "splash = false" >> $HYPRPAPER_CONF

# hyprpaper restart
killall hyprpaper
hyprpaper &
