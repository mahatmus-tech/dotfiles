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
    whiptail --title "Select Options" --checklist "Choose options to install or configure\nNOTE: 'SPACEBAR' to select & 'TAB' key to change selection" 16 68 7
)

# Add the remaining static options
options_command+=(
    "dotfiles"      "> Install dotfiles.git in ~/Projects" "ON"
    "applications"  "> Install applications"               "ON"
    "scripts"       "> Install scripts in ~/Scripts"       "ON"
    "configs"       "> Install configs in the system"      "ON"    
    "kitty"         "> Install Kitty Settings"             "ON"    
    "hyprland"      "> Install Hyprland Settings"          "ON"
    "mods"          "> Install Game Mods"                  "OFF"    
    "tkg"           "> Install TKG Kernel"                 "OFF"
)

# ======================
# INSTALLATION FUNCTIONS
# ======================

info()             { echo -e "${BLUE}[i]${NC} $1"; }
warning()          { echo -e "${YELLOW_W}[!]${NC} $1"; }
error()            { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
status()           { echo -e "${GREEN}[+]${YELLOW} $1${NC}"; }
status_step()      { echo -e "${GREEN}    -${NC} $1"; }
status_step_info() { echo -e "${GREEN}      >${BLUE} $1"; }


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
        if ! pacman -Q "$pkg" &>/dev/null; then
            sudo -v
            status_step_info "$pkg"
            sudo pacman -S --needed --noconfirm --quiet "$pkg" >/dev/null 2>&1 || {
                warning "Failed to install $pkg. Continuing..."
                return 1
            }
        fi
    done
}


install_aur() {
    local pkg
    for pkg in "$@"; do
        if ! paru -Q "$pkg" &>/dev/null; then
            sudo -v
            status_step_info "$pkg"
            paru -S --needed --noconfirm --quiet "$pkg" >/dev/null 2>&1 || {
                warning "Failed to install $pkg. Continuing..."
                return 1
            }
        fi
    done
}

copy_file() {
    local file=$1 dest=$2
    sudo rm -f "$dest/$file"
    if ! sudo cp "$file" "$dest"; then
        error "Failed to copy $file"
        return 1
    fi
    sudo chmod +rwx "$dest/$file"
}

clone_and_build() {
    local repo_url=$1
    local dir_name=$2
    local build_cmd=${3:-"makepkg -si --needed --noconfirm >/dev/null 2>&1"}

    sudo rm -rf "$INSTALL_DIR/$dir_name"
    git clone -q "$repo_url" >/dev/null 2>&1 "$INSTALL_DIR/$dir_name" || error "Failed to clone $dir_name"
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

# ======================
# INSTALLATION SECTIONS
# ======================

install_dotfiles() {
    status "Installing Dotfiles Project"
    INSTALL_DIR="$HOME/Projects"

    clone_and_build "https://github.com/mahatmus-tech/dotfiles.git" "dotfiles" \
                    " "
}

install_apps() {
    status "Installing Apps"

    # Update packages
	paru -Syu --needed --noconfirm --noprogressbar >/dev/null

    status_step "Coding"
    install_packages emacs-wayland bash-completion

    status_step "Basic Edition"
    install_packages micro

    status_step "RDP"
    install_packages rdesktop

    status_step "Browser"
    install_aur brave-bin

    status_step "Call"
    install_aur vesktop-bin teams-for-linux

    status_step "AnyDesk"
    install_aur anydesk-bin

    status_step "Spotify compatible with wayland"
    # -------------------------------------------
        cd "$HOME/Projects/dotfiles/configs"
        install_packages spotify-launcher
        copy_file spotify-launcher.conf "$HOME/.config"
    # -------------------------------------------

    status_step "LossLess Scaling for Linux"
    # -------------------------------------------
        install_aur lsfg-vk-git
        #cd "$HOME/Projects/dotfiles/configs"
        #copy_file conf.toml "$HOME/.config/lsfg-vk"
    # -------------------------------------------    

    status_step "Razer Support"
    # -------------------------------------------
        #DPI/Light Control
        sudo gpasswd -a $USER plugdev
        install_aur polychromatic

        #Key Mapping
        install_aur input-remapper-git
        sudo systemctl enable --now input-remapper

        # Download Presets
        #cd "$HOME/Projects/dotfiles/configs"
        #mkdir -p "$HOME"/.config/input-remapper-2/presets/{Razer Razer Orbweaver,Razer Razer Naga Epic}
        #copy_file Razer Razer Orbweaver "$HOME/.config/input-remapper-2/presets"
        #copy_file Razer Razer Naga Epic "$HOME/.config/input-remapper-2/presets"
    # -------------------------------------------    

    status_step "blstrobe"
    clone_and_build "https://github.com/fhunleth/blstrobe.git" "blstrobe" \
                    "./autogen.sh >/dev/null && ./configure >/dev/null && make -s >/dev/null && sudo make -s install >/dev/null"
}

install_scripts() {
    status "Installing Scrips"
    cd "$HOME/Projects/dotfiles/scripts"

    copy_file blstrobe-start.sh "$HOME/Scripts"
    copy_file camera-sara.sh "$HOME/Scripts"
    copy_file remote-senior.sh "$HOME/Scripts"
    copy_file benq-monitor "/usr/bin"
    copy_file tv-monitor "/usr/bin"
}

install_configs() {
    status "Installing Configs"
    cd "$HOME/Projects/dotfiles/configs"

    status_step "Game Cache Directories"
    mkdir -p "$HOME"/.cache/games/{marvelrivals,ow2,elden.ring,nightreign}

    #status_step "Mangohud Preset"
    #copy_file MangoHud.conf "$HOME/.config/MangoHud"

    status_step "Mouse Freeze Fix"
    copy_file 48-mouse-fix.rules /usr/lib/udev/rules.d
    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=usb --action=add
}

install_mods() {
    status "Installing Gaming Mods"
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

configure_hyprland() {
    status "Configuring Hyprland"
	local CONFIG=""

    status_step "Monitor"
    # ----------------------------
        cd "$HOME/Projects/dotfiles/configs"

        status_step_info "2-monitors"
        copy_file 2-monitors.conf "$HOME/.config/hypr"
        copy_file 2-monitors.conf "$HOME/.config/hypr/Monitor_Profiles"

        status_step_info "3-monitors"
        copy_file 3-monitors.conf "$HOME/.config/hypr/Monitor_Profiles"

        #status_step_info "2-monitors as Default"
        #sudo rm -f "$HOME/.config/hypr/monitors.conf"
        #mv "$HOME/.config/hypr/2-monitors.conf" "$HOME/.config/hypr/monitors.conf"
    # ----------------------------
	
    status_step "Startup_Apps"
    # ------------------------
        CONFIG="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"

        echo -e "\n# -----------\n# My Settings\n# -----------\n" >> "$CONFIG"
        status_step_info "BLStrobe"
        echo "exec-once = ~/Scripts/blstrobe-start.sh" >> "$CONFIG"
    # ------------------------

    status_step "UserKeybinds"
    # ------------------------
        CONFIG="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
        echo -e "\n# -----------\n# My Settings\n# -----------\n" >> "$CONFIG"

        status_step_info "Camera Sara"
        echo "bind = \$mainMod SHIFT, C, exec, ~/Scripts/camera-sara.sh" >> "$CONFIG"

        status_step_info "Remote Senior"
        echo "bind = \$mainMod SHIFT, R, exec, ~/Scripts/remote-senior.sh" >> "$CONFIG"
    # ------------------------

    status_step "UserKeybinds"
    # ------------------------
        CONFIG="$HOME/.config/hypr/UserConfigs/UserSettings.conf"

        status_step_info "Keyboard Layout"
        sudo sed -i -E "s/kb_variant =/kb_variant = intl/g" "$CONFIG"

        status_step_info "Default Monitor"
        sudo sed -i -E '/cursor \{/!b;n;c\ \ default_monitor = DP-3' "$CONFIG"

        status_step_info "Enable HDR"
        echo -e "experimental {\n  xx_color_management_v4 = true\n}" >> "$CONFIG"
        # https://wiki.archlinux.org/title/HDR_monitor_support

        #status_step_info "Allow Tearing"
        #sudo sed -i -E '/general \{/!b;n;c\ \ allow_tearing = true' "$CONFIG"
        #sudo sed -i -E "s/general {/general { \n  allow_tearing = true/g" "$CONFIG"
        #vrr = 3

        status_step_info "Layout to Master"
        sudo sed -i -E "s/layout = dwindle/layout = master/g" "$CONFIG"        
    # ------------------------    
    
    status_step "WindowRules"
    # -----------------------
        CONFIG="$HOME/.config/hypr/UserConfigs/WindowRules.conf"

        status_step_info "Game Tag"
        echo -e "\n# Game Tag" >> "$CONFIG"
        echo "windowrulev2 = tag +games, class:^(marvel-win64-shipping.exe)$" >> "$CONFIG"
        echo "windowrulev2 = tag +games, class:^(overwatch.exe)$" >> "$CONFIG"
        echo "windowrulev2 = tag +games, class:^(eldenring.exe)$" >> "$CONFIG"
        echo "windowrulev2 = tag +games, class:^(nightreign.exe)$" >> "$CONFIG"

        status_step_info "workspace"
        echo -e "\n# Workspace" >> "$CONFIG"
        echo "windowrulev2 = workspace 4, tag:im*" >> "$CONFIG"    
        echo "windowrulev2 = workspace 5, tag:gamestore*" >> "$CONFIG"    
        echo "windowrulev2 = workspace 1, class:^(rdesktop)$" >> "$CONFIG"
        echo "windowrulev2 = workspace 5, class:^(spotify)$" >> "$CONFIG"

        status_step_info "Always ON"
        echo -e "\n# Always ON" >> "$CONFIG"
        echo "windowrulev2 = idleinhibit always, tag:im*" >> "$CONFIG"
        echo "windowrulev2 = idleinhibit always, class:^(rdesktop)$" >> "$CONFIG"

        status_step_info "Position Fix"
        echo -e "\n# Brave save window fix" >> "$CONFIG"
        echo "windowrulev2 = center, title:.*wants to save.*" >> "$CONFIG"
        echo "windowrulev2 = center, class:^(vesktop)$" >> "$CONFIG"

        status_step_info "Camera sara"
        echo -e "\n# camera sara" >> "$CONFIG"
        echo "windowrulev2 = workspace 4, class:ffplay" >> "$CONFIG"
        echo "windowrulev2 = move 72% 7%, class:ffplay" >> "$CONFIG"

        status_step_info "Workspace Rules"
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
    # -----------------------
}

configure_kitty() {
    status "Configuring Kitty"
	local CONFIG=""

    status_step "Terminal Theme"
    cd "$HOME/Projects/dotfiles/configs"        
    copy_file kitty.conf "$HOME/.config/kitty"
    copy_file hyde-theme.conf "$HOME/.config/kitty/kitty-themes"

    status_step "Pokemon-Colorscripts"
    CONFIG="$HOME/.zshrc"
    sudo sed -i -E "s/pokemon-colorscripts --no-title -s -r/pokemon-colorscripts -r1/g" "$CONFIG"    

    #Ctrl+B: Waybar style = [WALLUST] Latte-wallust combined v2
    #Alt+B: waybar layout = [TOP] Minimal - Long
    #Shift+A: 03 - disable animation
}

install_tkg_kernel() {
    status "Installing Linux-Tkg Kernel"
    clone_and_build "https://github.com/Frogging-Family/linux-tkg.git" "linux-tkg" \
                    "makepkg -si"

    status_step "Add TKG Kernel in Systemd Boot Loader"
    # -------------------------------------------------
        cd "$HOME/Projects/dotfiles/configs"

        local root_partuuid=$(blkid -s PARTUUID -o value "$(findmnt -no SOURCE /)")
        local kernel_name=$(sudo find /boot -maxdepth 1 -type f -name '*vmlinuz*tkg*' -printf '%f\n' | sed 's/^vmlinuz-//')
        local vmlinuz_name=$(sudo find /boot -maxdepth 1 -type f -name '*vmlinuz*tkg*' -printf '%f\n')
        local initramfs_name=$(sudo find /boot -maxdepth 1 -type f -name '*initramfs*tkg*' ! -name '*fallback*' -printf '%f\n')
        local initramfs_fallback_name=$(sudo find /boot -maxdepth 1 -type f -name '*initramfs*tkg*' -name '*fallback*' -printf '%f\n')
        
        # Copy base conf files
        copy_file linux-tkg.conf "/boot/loader/entries"
        copy_file linux-tkg-fallback.conf "/boot/loader/entries"
        # Set the kernel name
        sudo sed -i -E "s|ARCHTKG|$kernel_name|" /boot/loader/entries/linux-tkg.conf
        sudo sed -i -E "s|ARCHTKG|$kernel_name|" /boot/loader/entries/linux-tkg-fallback.conf
        # Set vmlinuz
        sudo sed -i -E "s|VMLINUZ|$vmlinuz_name|" /boot/loader/entries/linux-tkg.conf
        sudo sed -i -E "s|VMLINUZ|$vmlinuz_name|" /boot/loader/entries/linux-tkg-fallback.conf
        # Set initramfs
        sudo sed -i -E "s|INITRAMFS|$initramfs_name|" /boot/loader/entries/linux-tkg.conf
        sudo sed -i -E "s|INITRAMFS|$initramfs_fallback_name|" /boot/loader/entries/linux-tkg-fallback.conf          
        # Set the root id
        sudo sed -i -E "s|PATITION_ID|$root_partuuid|" /boot/loader/entries/linux-tkg.conf
        sudo sed -i -E "s|PATITION_ID|$root_partuuid|" /boot/loader/entries/linux-tkg-fallback.conf

        sudo bootctl set-default linux-tkg.conf
    # -------------------------------------------------

    status_step "Remove Others Linux Kernel"
    # --------------------------------------
        sudo pacman -R linux-zen-headers linux-zen --noconfirm
        sudo find /boot -maxdepth 1 -type f ! \( -name '*tkg*' -o -name '*ucode*' \) -exec rm -f {} \;
        sudo find /boot/loader/entries -maxdepth 1 -type f ! \( -name '*tkg*' \) -exec rm -f {} \;
        sudo find /etc/mkinitcpio.d -maxdepth 1 -type f ! \( -name '*tkg*' \) -exec rm -f {} \;
    # --------------------------------------
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
            kitty)
                configure_kitty
                ;;
            hyprland)
                configure_hyprland
                ;;
            mods)
                install_mods
                ;;                                
            tkg)
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