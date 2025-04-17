#!/usr/bin/env bash

# Before using yay, check if it exists
install_aur() {
    if ! command -v yay >/dev/null; then
        error "yay is not installed. Cannot install AUR packages."
        return 1
    fi
    # rest of function...
}

install_aur() {
    status "Installing AUR packages: $*"
    yay -S --needed --noconfirm "$@" || {
        warning "Failed to install some AUR packages. Continuing..."
        return 1
    }
}

install_packages micro
    # Cooler Master MM720 mouse fix
    sudo rm -f /etc/udev/rules.d/99-mm720-power.rules
    sudo wget -P /etc/udev/rules.d https://raw.githubusercontent.com/mahatmus-tech/arch-auto-install/refs/heads/main/files/99-mm720-power.rules
    sudo udevadm control --reload
    sudo udevadm trigger  # Apply new rules without reboot

    # RDP client
    install_packages rdesktop

    install_aur brave-bin teams-for-linux

    # coding
    install_packages emacs-wayland bash-completion docker docker-compose
    sudo usermod -aG gamemode $USER

    status "Installing flatpak..."
    install_packages flatpak

    install_pipewire_audio() {
    status "Installing audio packages..."
	# remove conflicting packages
	sudo pacman -R --noconfirm jack2
    # install audio packages
    install_packages \
		pipewire pipewire-alsa pipewire-jack pipewire-pulse \
		lib32-pipewire alsa-utils alsa-plugins alsa-ucm-conf \
		gst-plugin-pipewire wireplumber 
}

    if [ "$YAY_INSTALLED" = true ]; then
        install_aur brave-bin teams-for-linux
    fi

   status "Installing snap..."
    clone_and_build "https://aur.archlinux.org/snapd.git" "snapd"
    sudo systemctl enable --now snapd.socket snapd.service
    sudo systemctl restart snapd.socket snapd.service    
    sudo ln -s /var/lib/snapd/snap /snap

    if [ "$SNAP_INSTALLED" = true ]; then
        sudo snap install spotify
    fi

    status "Installing yay (AUR helper)..."
    clone_and_build "https://aur.archlinux.org/yay-bin.git" "yay-bin"
    $YAY_INSTALLED=true
