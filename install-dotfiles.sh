#!/usr/bin/env bash

#!/bin/bash

set -euo pipefail

# ======================
# GLOBAL VARIABLES
# ======================

# Default install dir
INSTALL_DIR="$HOME/Apps"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values for the options
dotfiles="OFF"
applications="OFF"
scripts="OFF"
configs="OFF"
mods="OFF"
hyprland="OFF"

# Initialize the options array for whiptail checklist
options_command=(
    whiptail --title "Select Options" --checklist "Choose options to install or configure\nNOTE: 'SPACEBAR' to select & 'TAB' key to change selection" 28 85 20
)

# Add the remaining static options
options_command+=(
    "dotfiles"      "Install your dotfiles.git in ~/Projects"     "ON"
    "applications"  "Install your personal applications"          "ON"
    "scripts"       "Install your scripts in ~/Scripts"           "ON"
    "configs"       "Install your configs in the system"          "ON"
    "mods"          "Install your mods to their folder games"     "ON"
    "hyprland"      "Install your personal settings in Hyprland"  "ON"
)

# ======================
# INSTALLATION FUNCTIONS
# ======================

status() { echo -e "${GREEN}[+]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

install_packages() {    
    local pkg
    for pkg in "$@"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            status "Installing package: $pkg"
            sudo pacman -S -qq --needed --noconfirm --noprogressbar "$pkg" 2>/dev/null || {
                warning "Failed to install $pkg. Continuing..."
                return 1
            }
        fi
    done
}

install_aur() {
    local pkg
    for pkg in "$@"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            status "Installing AUR package: $pkg"
            yay -S -qq --needed --noconfirm --noprogressbar "$pkg" 2>/dev/null || {
                warning "Failed to install $pkg. Continuing..."
                return 1
            }
        fi
    done
}


show_menu() {
    install_packages libnewt
    
    # Capture the selected options before the while loop starts
    while true; do
        selected_options=$("${options_command[@]}" 3>&1 1>&2 2>&3)

        # Check if the user pressed Cancel (exit status 1)
        if [ $? -ne 0 ]; then
            echo -e "\n"
            echo "You cancelled the selection. Goodbye!"
            exit 0  # Exit the script if Cancel is pressed
        fi

        # If no option was selected, notify and restart the selection
        if [ -z "$selected_options" ]; then
            whiptail --title "Warning" --msgbox "No options were selected. Please select at least one option." 10 60
            continue  # Return to selection if no options selected
        fi

        # Strip the quotes and trim spaces if necessary (sanitize the input)
        selected_options=$(echo "$selected_options" | tr -d '"' | tr -s ' ')

        # Convert selected options into an array (preserving spaces in values)
        IFS=' ' read -r -a options <<< "$selected_options"

        info "You confirmed your choices. Proceeding with Installation..."
        break
    done
}

copy_file() {
    local file=$1 dest=$2
    sudo rm -f "$dest/$file"
    if ! sudo cp "$file" "$dest"; then
        error "Failed to copy $file"
        return 1
    fi
}

clone_and_build() {
    local repo_url=$1
    local dir_name=$2
    local build_cmd=${3:-"makepkg -si --noconfirm"}
    
    status "Building $dir_name from source..."
    sudo rm -rf "$INSTALL_DIR/$dir_name"
    git clone -q "$repo_url" "$INSTALL_DIR/$dir_name" || error "Failed to clone $dir_name"
    cd "$INSTALL_DIR/$dir_name" || error "Failed to enter $dir_name directory"
    sudo chown -R "$USER" . || error "Failed to change ownership"
    sudo chmod -R 755 . || error "Failed to change permissions"
    eval "$build_cmd" || warning "Failed to build/install $dir_name"
    cd - >/dev/null || error "Failed to return to previous directory"
}


# ======================
# INSTALLATION SECTIONS
# ======================

install_dotfiles() {
    status "Downloading Project..."
    INSTALL_DIR="$HOME/Projects"
    clone_and_build "https://github.com/mahatmus-tech/dotfiles.git" "dotfiles" \
                    "echo "Git Dotfiles Downloaded!" "
}

install_apps() {
    status "Update AUR and Pacman packages ..."
	yay -Syuq --needed --noconfirm --noprogressbar
    # Coding
    install_packages emacs-wayland bash-completion
    # Basic Edition
    install_packages micro
    # RDP
    install_packages rdesktop
    # Browser
    install_aur brave-bin
    # Call
    install_aur vesktop-bin teams-for-linux
    # Audio
    install_aur spotify
	# remove conflicting package with pipewire
	#sudo pacman -R --noconfirm jack2
    # blstrobe
    clone_and_build "https://github.com/fhunleth/blstrobe.git" "blstrobe" \
                    "chmod +x autogen.sh configure && ./autogen.sh && ./configure && make && sudo make install"
}

install_scripts() {
    status "Installing Scrips ..."
    cd "$HOME/Projects/dotfiles/scripts"

    copy_file blstrobe-start.sh "$HOME/Scripts"
    copy_file camera-sara.sh "$HOME/Scripts"
    copy_file remote-senior.sh "$HOME/Scripts"
}

install_configs() {
    status "Installing Configs ..."
    cd "$HOME/Projects/dotfiles/configs"

    status "Installing 2 Monitor config ..."
    copy_file 120hz.conf "$HOME/.config/hypr/Monitor_Profiles"
    copy_file 120hz.conf "$HOME/.config/hypr"
    sudo rm -f "$HOME/.config/hypr/monitors.conf"
    mv "$HOME/.config/hypr/120hz.conf" "$HOME/.config/hypr/monitors.conf"

    status "Installing Cooler Master MM720 Freeze Fix..."
    copy_file cooler-master-mm720-fix.conf /etc/modprobe.d
    sudo mkinitcpio -P
}

install_mods() {
    status "Installing Mods..."
    cd "$HOME/Projects/dotfiles/mods"

    cd marvel-rivals
    # Mod marvel rivals
    # https://www.nexusmods.com/marvelrivals/mods/273?tab=description
    # In ta mod folder, copy to the game file on steam. Check the gameID of the game 2767030    
    copy_file Scalability.ini "$HOME/.steam/steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/"
}

install_hyprland_settings() {
    status "Configuring Hyprland..."
	local CONFIG=""
	
    CONFIG="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
    echo "exec-once = ~/Scripts/blstrobe-start.sh" >> "$CONFIG"
    
    CONFIG="$HOME/.config/hypr/UserConfigs/WindowRules.conf"
    # Default Monitor for gaming
    echo "windowrulev2 = monitor DP-3, tag:games*" >> "$CONFIG"
    # always on in teams-for-linux
    echo "windowrulev2 = idleinhibit always, tag:im*" >> "$CONFIG"
    # brave save option in center
    echo "windowrulev2 = center, title:.*wants to save.*" >> "$CONFIG"
    # set default workspaces
    echo "workspace = 1, monitor:DP-3, default:true" >> "$CONFIG"
    echo "workspace = 2, monitor:DP-3" >> "$CONFIG"
    echo "workspace = 3, monitor:DP-3" >> "$CONFIG"
    echo "workspace = 4, monitor:DP-1" >> "$CONFIG"
    echo "workspace = 5, monitor:DP-1" >> "$CONFIG"
    echo "workspace = 6, monitor:DP-3" >> "$CONFIG"
    echo "workspace = 7, monitor:DP-3" >> "$CONFIG"
    echo "workspace = 8, rounding:false, decorate:false, gapsin:0, gapsout:0, border:false, decorate:false, monitor:DP-3" >> "$CONFIG"

    CONFIG="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
    echo "bind = $mainMod SHIFT, C, exec, ~/Scripts/camera-sara.sh" >> "$CONFIG"
    echo "bind = $mainMod SHIFT, R, exec, ~/Scripts/remote-senior.sh" >> "$CONFIG"

    #change .config/kitty/kitty.conf
    #font_family ttf-jetbrains-mono

    #Set waybar style = ML4W
    #Set waybar layout = [TOP] Sleek    
}


# ======================
# MAIN INSTALLATION FLOW
# ======================
main() {
	echo -e "\n${GREEN}🚀 Starting DotFiles Install ${NC}"
    
    show_menu

    # Clean up the selected options (remove quotes and trim spaces)
    selected_options=$(echo "$selected_options" | tr -d '"' | tr -s ' ')

    # Convert selected options into an array (splitting by spaces)
    IFS=' ' read -r -a options <<< "$selected_options"

    # Loop through selected options
    for option in "${options[@]}"; do
        case "$option" in
            dotfiles)
                install_dotfiles
                ;;
            applications)
                install_apps
                ;;
            scripts)
                install_scripts
                ;;
            configs)
                install_configs
                ;;
            mods)
                install_mods
                ;;
            hyprland)
                install_hyprland_settings
                ;;
            *)
                echo "Unknown option: $option"
                ;;
        esac
    done
	
	echo -e "\n${GREEN} Installation completed successfully! ${NC}"
	echo -e "${YELLOW} Please reboot your system to apply all changes. ${NC}"
}

# Execute
main