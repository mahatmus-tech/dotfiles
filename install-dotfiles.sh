#!/usr/bin/env bash


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

    status "Installing flatpak..."
    install_packages flatpak

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
