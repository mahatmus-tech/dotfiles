#!/usr/bin/env bash

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

# Menu configuration
MENU_OPTIONS=(
	1  "Download Project" on
    2  "Install Apps"     on
    3  "Install Scripts"  on
    4  "Install Configs"  on
    5  "Install Mods"     off
    6  "Configure Linux"  on
)


# ======================
# INSTALLATION FUNCTIONS
# ======================

status() { echo -e "${GREEN}[+]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

install_packages() {
    status "Installing packages: $*"
    sudo pacman -S --needed --noconfirm "$@" || {
        warning "Failed to install some packages. Continuing..."
        return 1
    }
}

install_aur() {
    status "Installing AUR packages: $*"
    yay -S --needed --noconfirm "$@" || {
        warning "Failed to install some AUR packages. Continuing..."
        return 1
    }
}

show_menu() {
    install_packages dialog
    dialog --clear \
        --title "Arch Hyprland Installation" \
        --checklist "Select components to install:" 20 60 15 \
        "${MENU_OPTIONS[@]}" 2>selected
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
    git clone "$repo_url" "$INSTALL_DIR/$dir_name" || error "Failed to clone $dir_name"
    cd "$INSTALL_DIR/$dir_name" || error "Failed to enter $dir_name directory"
    sudo chown -R "$USER" . || error "Failed to change ownership"
    sudo chmod -R 755 . || error "Failed to change permissions"
    eval "$build_cmd" || warning "Failed to build/install $dir_name"
    cd - >/dev/null || error "Failed to return to previous directory"
}


# ======================
# INSTALLATION SECTIONS
# ======================

download_project() {
    status "Downloading Project..."
    INSTALL_DIR="$HOME/Projects"
    clone_and_build "https://github.com/mahatmus-tech/dotfiles.git" "dotfiles" \
                    "echo "Git Dotfiles Downloaded!" "
}

install_apps() {
	status "Installing Apps ..."

 	# Update AUR and Pacman ackages
	yay -Syu --needed --noconfirm
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
	sudo pacman -R --noconfirm jack2
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

configure_linux() {
    status "Configuring Hyprland..."
	local CONFIG=""
	
    CONFIG="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
    echo "exec-once = ~/Scripts/blstrobe-start.sh" >> "$CONFIG"
    
    CONFIG="$HOME/.config/hypr/UserConfigs/WindowRules.conf"
    echo "windowrulev2 = monitor DP-3, tag:games*" >> "$CONFIG"

    CONFIG="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
    echo "bind = $mainMod SHIFT, C, exec, ~/Scripts/camera-sara.sh" >> "$CONFIG"
    echo "bind = $mainMod SHIFT, R, exec, ~/Scripts/remote-senior.sh" >> "$CONFIG"    
}


# ======================
# MAIN INSTALLATION FLOW
# ======================
main() {
	echo -e "\n${GREEN}🚀 Starting My DotFiles Install ${NC}"
    
    show_menu

    mapfile -t SELECTIONS < selected
    rm -f selected

    for selection in "${SELECTIONS[@]}"; do
        case $selection in
            1)  download_project ;;
            2)  install_apps ;;
            3)  install_scripts ;;
            4)  install_configs ;;
            5)  install_mods ;;
            6)  configure_linux ;;
        esac
    done
	
	echo -e "\n${GREEN} Installation completed successfully! ${NC}"
	echo -e "${YELLOW} Please reboot your system to apply all changes. ${NC}"
}

# Execute
main

