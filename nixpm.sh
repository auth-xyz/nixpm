#!/bin/sh

# Define paths for system-wide and user-specific configurations
SYSTEM_CONFIG="/etc/nixos/packages.nix"
USER_CONFIG="$HOME/.config/home-manager/packages.nix"

# Function to add a package to the system config
add_system_package() {
    package_name=$1
    if grep -q "\b$package_name\b" "$SYSTEM_CONFIG"; then
        echo "$package_name is already in the system configuration."
    else
        sed -i "/environment.systemPackages = with pkgs;/a \    $package_name" "$SYSTEM_CONFIG"
        echo "Added $package_name to system configuration."
    fi
}

# Function to add a package to the user config
add_user_package() {
    package_name=$1
    if grep -q "\b$package_name\b" "$USER_CONFIG"; then
        echo "$package_name is already in the user configuration."
    else
        sed -i "/home.packages = with pkgs;/a \    $package_name" "$USER_CONFIG"
        echo "Added $package_name to user configuration."
    fi
}

# Determine if the script is running as root
if [ "$EUID" -eq 0 ]; then
    # Ensure the system config file exists
    if [ ! -f "$SYSTEM_CONFIG" ]; then
        echo -e "{ pkgs, ... }:\n{\n  environment.systemPackages = with pkgs; [\n    \n  ];\n}" > "$SYSTEM_CONFIG"
    fi
    
    # Add package to system configuration
    for package in "$@"; do
        add_system_package "$package"
    done

else
    # Ensure the user config file exists
    if [ ! -f "$USER_CONFIG" ]; then
        mkdir -p "$(dirname "$USER_CONFIG")"
        echo -e "{ pkgs, ... }:\n{\n  home.packages = with pkgs; [\n     \n  ];\n}" > "$USER_CONFIG"
    fi
    
    # Add package to user configuration
    for package in "$@"; do
        add_user_package "$package"
    done
fi

