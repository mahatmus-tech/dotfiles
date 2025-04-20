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

safe_download() {
    local dest=$1 url=$2
    if ! sudo wget -P "$dest" -q --show-progress "$url"; then
        error "Failed to download $url"
        return 1
    fi
}

clone_and_build() {
    local repo_url=$1
    local dir_name=$2
    local build_cmd=${3:-"makepkg -si --noconfirm"}
    local clone_flags=$4  # No default

    status "Building $dir_name from source..."
    sudo rm -rf "$INSTALL_DIR/$dir_name"
    git clone $clone_flags "$repo_url" "$INSTALL_DIR/$dir_name" || error "Failed to clone $dir_name"
    cd "$INSTALL_DIR/$dir_name" || error "Failed to enter $dir_name directory"
    sudo chown -R "$USER":"$USER" . || error "Failed to change ownership"
    sudo chmod -R 755 . || error "Failed to change permissions"
    eval "$build_cmd" || warning "Failed to build/install $dir_name"
    cd - >/dev/null || error "Failed to return to previous directory"
}

# ======================
# INSTALLATION SECTIONS
# ======================
install_my_packages() {
	status "Installing My Packages ..."
 	# Update AUR and Pacman ackages
	yay -Syu --needed --noconfirm
    # Coding
    install_packages emacs-wayland bash-completion
    # Basic Edition
    install_packages micro
    #RDP
    install_packages rdesktop
    # Browser
    install_aur brave-bin
    # Call
    install_aur vesktop-bin teams-for-linux
    # Audio
    install_aur spotify
	# remove conflicting packages
	sudo pacman -R --noconfirm jack2
    #Blstrobe

}

# ======================
# POST-INSTALL
# ======================
configure_linux() {
    status "Configuring My Linux..."
	local CONFIG=""

    # Cooler Master MM720 mouse fix
    sudo rm -f /etc/udev/rules.d/99-mm720-power.rules
    safe_download /etc/udev/rules.d https://raw.githubusercontent.com/mahatmus-tech/arch-auto-install/refs/heads/main/files/99-mm720-power.rules
    sudo udevadm control --reload
    sudo udevadm trigger  # Apply new rules without reboot        

    # Mod marvel rivals
    # https://www.nexusmods.com/marvelrivals/mods/273?tab=description
    # In ta mod folder, copy to the game file on steam. Check the gameID of the game 2767030
    cp Scalability.ini /home/mahatmus/.steam/steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/    
	
		CONFIG="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
		echo "exec-once = ~/Scripts/blstrobe-start.sh" >> "$CONFIG"
		
		CONFIG="$HOME/.config/hypr/UserConfigs/WindowRules.conf"
		echo "# my settings" >> "$CONFIG"
		echo "windowrulev2 = content game, tag:games*" >> "$CONFIG"
		echo "windowrulev2 = nodim, tag:games*" >> "$CONFIG"
		echo "windowrulev2 = noanim, tag:games*" >> "$CONFIG"
		echo "windowrulev2 = noborder, tag:games*" >> "$CONFIG"
		echo "windowrulev2 = noshadow, tag:games*" >> "$CONFIG"
		echo "windowrulev2 = norounding, tag:games*" >> "$CONFIG"
		echo "windowrulev2 = allowsinput, tag:games*" >> "$CONFIG"
		echo "windowrulev2 = immediate, tag:games*" >> "$CONFIG"
		
		CONFIG="$HOME/.config/hypr/UserConfigs/UserSettings.conf"
		sudo sed -i -E "s|#accel_profile =|accel_profile = flat|" "$CONFIG"
		sudo sed -i -E "s|direct_scanout = 0|direct_scanout = 2|" "$CONFIG"

        CONFIG="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
        echo "bind = $mainMod SHIFT, C, exec, ~/Scripts/camera-sara.sh" >> "$CONFIG"
        

		CONFIG="$HOME/.zprofile"
  		sudo sed -i -E "s/#/ /g" "$CONFIG"

		if [ "$GPU" = "nvidia" ]; then
			CONFIG="$HOME/.config/hypr/UserConfigs/ENVariables.conf"
			# Force GBM as a backend
			echo "# my settings" >> "$CONFIG"
			echo "env = GBM_BACKEND,nvidia-drm" >> "$CONFIG"
			echo "env = __GLX_VENDOR_LIBRARY_NAME,nvidia" >> "$CONFIG"

			# Hardware acceleration on NVIDIA GPUs
			echo "env = LIBVA_DRIVER_NAME,nvidia" >> "$CONFIG" 
		fi
}

# ======================
# MAIN INSTALLATION FLOW
# ======================
main() {
	echo -e "\n${GREEN}🚀 Starting My DotFiles Install ${NC}"

	install_my_packages
	configure_linux
	
	echo -e "\n${GREEN} Installation completed successfully! ${NC}"
	echo -e "${YELLOW} Please reboot your system to apply all changes. ${NC}"
}

# Execute
main

