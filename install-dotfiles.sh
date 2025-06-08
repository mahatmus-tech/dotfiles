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
YELLOW='\033[0;33m'
YELLOW_W='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize the options array for whiptail checklist
options_command=(
    whiptail --title "Select Options" --checklist "Choose options to install or configure\nNOTE: 'SPACEBAR' to select & 'TAB' key to change selection" 14 68 6
)

# Add the remaining static options
options_command+=(
    "dotfiles"      "> Install your dotfiles.git in ~/Projects"     "ON"
    "applications"  "> Install your personal applications"          "ON"
    "scripts"       "> Install your scripts in ~/Scripts"           "ON"
    "configs"       "> Install your configs in the system"          "ON"
    "mods"          "> Install your mods to their folder games"     "ON"
    "hyprland"      "> Install your personal settings in Hyprland"  "ON"
    "tkg"           "> Install TKG Kernel"  "ON"    
)

# ======================
# INSTALLATION FUNCTIONS
# ======================

status() { echo -e "${GREEN}[+]${YELLOW} $1${NC}"; }
status_step() { echo -e "${GREEN}    >${NC} $1"; }
warning() { echo -e "${YELLOW_W}[!]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

sudo_cache() {
    status "Saving Sudo Password"
    sudo -v
    
	# Allow makepkg without password (safer than editing sudoers directly)
	sudo rm -f /etc/sudoers.d/42-user-nopassword
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" | sudo tee /etc/sudoers.d/42-user-nopassword >/dev/null
}

sudo_release() {
	sudo rm -f /etc/sudoers.d/42-user-nopassword
}

install_packages() {    
    local pkg
    for pkg in "$@"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            status_step "$pkg"
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
        if ! yay -Qi "$pkg" &>/dev/null; then
            status_step "$pkg"
            yay -S -qq --needed --noconfirm --noprogressbar "$pkg" 2>/dev/null || {
                warning "Failed to install $pkg. Continuing..."
                return 1
            }
        fi
    done
}

clone_and_build() {
    local repo_url=$1
    local dir_name=$2
    local build_cmd=${3:-"makepkg -si --needed --noconfirm --noprogressbar"}

    status_step "$dir_name"
    sudo rm -rf "$INSTALL_DIR/$dir_name"
    git clone -q "$repo_url" "$INSTALL_DIR/$dir_name" || error "Failed to clone $dir_name"
    cd "$INSTALL_DIR/$dir_name" || error "Failed to enter $dir_name directory"
    sudo chown -R "$USER" . || error "Failed to change ownership"
    sudo chmod -R 755 . || error "Failed to change permissions"
    eval "$build_cmd" || warning "Failed to build/install $dir_name"
    cd - >/dev/null || error "Failed to return to previous directory"
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

# ======================
# INSTALLATION SECTIONS
# ======================

install_dotfiles() {
    status "Installing Dotfiles..."
    INSTALL_DIR="$HOME/Projects"
    clone_and_build "https://github.com/mahatmus-tech/dotfiles.git" "dotfiles" \
                    " "
}

install_apps() {
    status "Installing Apps..."

    # Update packages
	yay -Syuq --needed --noconfirm --noprogressbar >/dev/null

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
    # Spotify compatible with wayland
    install_packages spotify-launcher
    # AnyDesk
    install_aur anydesk-bin
    # blstrobe
    clone_and_build "https://github.com/fhunleth/blstrobe.git" "blstrobe" \
                    "./autogen.sh >/dev/null && ./configure >/dev/null && make -s >/dev/null && sudo make -s install >/dev/null"
}

install_scripts() {
    status "Installing Scrips..."
    cd "$HOME/Projects/dotfiles/scripts"

    copy_file blstrobe-start.sh "$HOME/Scripts"
    copy_file camera-sara.sh "$HOME/Scripts"
    copy_file remote-senior.sh "$HOME/Scripts"
    copy_file gaming-monitor.sh "$HOME/Scripts"
}

install_configs() {
    status "Installing Configs..."
    cd "$HOME/Projects/dotfiles/configs"
    
    status_step "Monitors Profile"
    copy_file 2-monitors.conf "$HOME/.config/hypr"
    copy_file 2-monitors.conf "$HOME/.config/hypr/Monitor_Profiles"
    copy_file 3-monitors.conf "$HOME/.config/hypr/Monitor_Profiles"
    sudo rm -f "$HOME/.config/hypr/monitors.conf"
    mv "$HOME/.config/hypr/2-monitors.conf" "$HOME/.config/hypr/monitors.conf"

    status_step "Spotify wayland config"
    copy_file spotify-launcher.conf "$HOME/.config"

    status_step "Default Directories"
    mkdir -p "$HOME"/.cache/games/{marvelrivals,ow2,eldenring,nightreign}

    status_step "Set Mangohud.conf"
    copy_file MangoHud.conf "$HOME/.config/MangoHud"

    status_step "Cooler Master MM720 Freeze Fix"
    copy_file cooler-master-mm720-fix.conf /etc/modprobe.d
    sudo mkinitcpio -P >/dev/null
}

install_mods() {
    status "Installing Mods..."
    cd "$HOME/Projects/dotfiles/mods"

    local game_path="$HOME/.steam/steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/"
    if [ -d "$game_path" ]; then
        cd marvel-rivals
        status_step "Marvel Rivals - FPS Performance Enhancer"
        # Mod marvel rivals
        # https://www.nexusmods.com/marvelrivals/mods/273?tab=description
        # In ta mod folder, copy to the game file on steam. Check the gameID of the game 2767030    
        copy_file Scalability.ini "$game_path"
    fi
}

install_hyprland_settings() {
    status "Installing Hyprland Settings..."
	local CONFIG=""
	
    CONFIG="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
    echo -e "\n# -----------\n# My Settings\n# -----------\n" >> "$CONFIG"
    # BLStrobe
    echo "exec-once = ~/Scripts/blstrobe-start.sh" >> "$CONFIG"
    
    CONFIG="$HOME/.config/hypr/UserConfigs/WindowRules.conf"
    echo -e "\n# Game Tag" >> "$CONFIG"
    echo "windowrulev2 = tag +games, class:^(marvel-win64-shipping.exe)$" >> "$CONFIG"
    echo "windowrulev2 = tag +games, class:^(overwatch.exe)$" >> "$CONFIG"
    echo "windowrulev2 = tag +games, class:^(eldenring.exe)$" >> "$CONFIG"
    echo "windowrulev2 = tag +games, class:^(nightreign.exe)$" >> "$CONFIG"

    echo -e "\n# Workspace" >> "$CONFIG"
    echo "windowrulev2 = workspace 4, tag:im*" >> "$CONFIG"    
    echo "windowrulev2 = workspace 5, tag:gamestore*" >> "$CONFIG"    
    echo "windowrulev2 = workspace 1, class:^(rdesktop)$" >> "$CONFIG"
    echo "windowrulev2 = workspace 5, class:^(spotify)$" >> "$CONFIG"

    echo -e "\n# Always ON" >> "$CONFIG"
    echo "windowrulev2 = idleinhibit always, tag:im*" >> "$CONFIG"
    echo "windowrulev2 = idleinhibit always, class:^(rdesktop)$" >> "$CONFIG"

    echo -e "\n# Brave save window fix" >> "$CONFIG"
    echo "windowrulev2 = center, title:.*wants to save.*" >> "$CONFIG"
    echo "windowrulev2 = center, class:^(vesktop)$" >> "$CONFIG"

    echo -e "\n# camera sara" >> "$CONFIG"
    echo "windowrulev2 = workspace 4, class:ffplay" >> "$CONFIG"
    echo "windowrulev2 = move 72% 7%, class:ffplay" >> "$CONFIG"

    echo -e "\n# Workspace Rules" >> "$CONFIG"
    echo "workspace = 1, monitor:DP-3, persistent:true, default:true" >> "$CONFIG"
    echo "workspace = 2, monitor:DP-3" >> "$CONFIG"
    echo "workspace = 3, monitor:DP-3" >> "$CONFIG"
    echo "workspace = 4, monitor:DP-1, persistent:true, default:true" >> "$CONFIG"
    echo "workspace = 5, monitor:DP-1" >> "$CONFIG"
    echo "workspace = 6, monitor:DP-3" >> "$CONFIG"
    echo "workspace = 7, monitor:DP-3" >> "$CONFIG"
    echo "workspace = 8, monitor:DP-3,     rounding:false, decorate:false, gapsin:0, gapsout:0, border:false, decorate:false, shadow:false" >> "$CONFIG"
    echo "workspace = 9, monitor:HDMI-A-1, rounding:false, decorate:false, gapsin:0, gapsout:0, border:false, decorate:false, shadow:false, default:true" >> "$CONFIG"

    CONFIG="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
    echo -e "\n# -----------\n# My Settings\n# -----------\n" >> "$CONFIG"
    echo "bind = \$mainMod SHIFT, C, exec, ~/Scripts/camera-sara.sh" >> "$CONFIG"
    echo "bind = \$mainMod SHIFT, R, exec, ~/Scripts/remote-senior.sh" >> "$CONFIG"

    CONFIG="$HOME/.config/hypr/UserConfigs/UserSettings.conf"
    sudo sed -i -E '/cursor \{/!b;n;c\ \ default_monitor = DP-3' "$CONFIG"
    echo -e "experimental {\n  xx_color_management_v4 = true\n}" >> "$CONFIG"


    # Change Pokemon-Colorscripts preferences
    CONFIG="$HOME/.zshrc"
    sudo sed -i -E "s/pokemon-colorscripts --no-title -s -r/pokemon-colorscripts -r1/g" "$CONFIG"

    #change .config/kitty/kitty.conf
    #font_family ttf-jetbrains-mono

    #Ctrl+B: Waybar style = [WALLUST] Colored
    #Alt+B: waybar layout = [TOP] Minimal - Long
    #Shift+A: ML4 - fast
}

install_tkg_kernel() {
    status "Installing Linux-Tkg Kernel..."
    clone_and_build "https://github.com/Frogging-Family/linux-tkg.git" "linux-tkg" \
                    "makepkg -si"

    status_step "Add TKG Kernel in Systemd Boot Loader"
    cd "$HOME/Projects/dotfiles/configs"
    copy_file linux-tkg.conf "/boot/loader/entries"
    copy_file linux-tkg-fallback.conf "/boot/loader/entries"

    local root_partuuid=$(blkid -s PARTUUID -o value "$(findmnt -no SOURCE /)")
    sudo sed -i -E "s|PATITION_ID|$root_partuuid|" /boot/loader/entries/linux-tkg.conf
    sudo sed -i -E "s|PATITION_ID|$root_partuuid|" /boot/loader/entries/linux-tkg-fallback.conf
    sudo bootctl set-default linux-tkg.conf

    status_step "Remove Others Linux Kernel"
    sudo pacman -R linux-zen-headers linux-zen --noconfirm
    sudo find /boot -maxdepth 1 -type f ! \( -name '*tkg*' -o -name '*ucode*' \) -exec rm -f {} \;
    sudo find /boot/loader/entries -maxdepth 1 -type f ! \( -name '*tkg*' \) -exec rm -f {} \;
    sudo find /etc/mkinitcpio.d -maxdepth 1 -type f ! \( -name '*tkg*' \) -exec rm -f {} \;

    # Download bore kernel.conf
    copy_file 69-bore-scheduler.conf "/usr/lib/sysctl.d"
    sudo sysctl --system
}



# ======================
# MAIN INSTALLATION FLOW
# ======================
main() {
	echo -e "\n${GREEN}🚀 Starting DotFiles Install ${NC}"
    
    sudo_cache    
    show_menu

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
            hyprland)
                install_tkg_kernel
                ;;                
            *)
                echo "Unknown option: $option"
                ;;
        esac
    done

    sudo_release
	
	echo -e "\n${GREEN} Installation completed successfully! ${NC}"
	echo -e "${YELLOW_W} Please reboot your system to apply all changes. ${NC}"
}

# Execute
main