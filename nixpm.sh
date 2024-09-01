#!/bin/sh

# Define paths for system-wide and user-specific configurations
SYSTEM_CONFIG="/etc/nixos/configuration.nix"
SYSTEM_PACKAGES="/etc/nixos/packages.nix"
USER_CONFIG="$HOME/.config/home-manager/home.nix"
USER_PACKAGES="$HOME/.config/home-manager/packages.nix"

# Function to check if a package exists in nixpkgs
search_package() {
    package_name=$1
    echo "Searching nixpkgs for: $package_name"
    if nix-env -q -v 0 "$package_name" | grep -q "$package_name"; then
        echo "Found package: $package_name"
        return 0
    else
        echo "Package $package_name not found."
        return 1
    fi
}

# Function to add a package to the system config
add_system_package() {
    package_name=$1
    if search_package "$package_name"; then
        if grep -q "\b$package_name\b" "$SYSTEM_PACKAGES"; then
            echo "$package_name is already in the system configuration."
        else
            sed -i "/environment.systemPackages = with pkgs;/a \    $package_name" "$SYSTEM_PACKAGES"
            echo "Added $package_name to system configuration."
        fi
    else
        read -p "Is the package name $package_name correct? (y/n): " correct_response
        if [[ "$correct_response" =~ ^[Yy]$ ]]; then
            echo "Please check the package name or add it manually."
        fi
    fi
}

# Function to add a package to the user config
add_user_package() {
    package_name=$1
    if search_package "$package_name"; then
        if grep -q "\b$package_name\b" "$USER_PACKAGES"; then
            echo "$package_name is already in the user configuration."
        else
            sed -i "/home.packages = with pkgs;/a \    $package_name" "$USER_PACKAGES"
            echo "Added $package_name to user configuration."
        fi
    else
        read -p "Is the package name $package_name correct? (y/n): " correct_response
        if [[ "$correct_response" =~ ^[Yy]$ ]]; then
            echo "Please check the package name or add it manually."
        fi
    fi
}

# Function to remove a package from the system config
remove_system_package() {
    package_name=$1
    if grep -q "\b$package_name\b" "$SYSTEM_PACKAGES"; then
        sed -i "/\b$package_name\b/d" "$SYSTEM_PACKAGES"
        echo "Removed $package_name from system configuration."
    else
        echo "$package_name is not in the system configuration."
    fi
}

# Function to remove a package from the user config
remove_user_package() {
    package_name=$1
    if grep -q "\b$package_name\b" "$USER_PACKAGES"; then
        sed -i "/\b$package_name\b/d" "$USER_PACKAGES"
        echo "Removed $package_name from user configuration."
    else
        echo "$package_name is not in the user configuration."
    fi
}

# Function to prompt for importing packages.nix
prompt_for_import() {
    config_file=$1
    packages_file=$2

    # Check if the import already exists
    if grep -q "\./packages.nix" "$config_file"; then
        echo "packages.nix is already imported in $config_file."
    else
        read -p "Would you like to import packages.nix into $config_file? (y/n): " import_response
        if [[ "$import_response" =~ ^[Yy]$ ]]; then
            # Insert the import line before the closing ];
            sed -i "/imports = \[/a \  ./packages.nix" "$config_file"
            echo "Imported packages.nix into $config_file."
        fi
    fi
}

# Function to prompt for rebuild
prompt_for_rebuild() {
    if [ "$EUID" -eq 0 ]; then
        read -p "Would you like to run 'sudo nixos-rebuild switch'? (y/n): " rebuild_response
        if [[ "$rebuild_response" =~ ^[Yy]$ ]]; then
            sudo nixos-rebuild switch
        fi
    else
        read -p "Would you like to run 'home-manager switch'? (y/n): " rebuild_response
        if [[ "$rebuild_response" =~ ^[Yy]$ ]]; then
            home-manager switch
        fi
    fi
}

# Function to display help message
display_help() {
    echo "Usage: $0 [options] [packages...]"
    echo "Options:"
    echo "  -a, --add         Add packages (default action)"
    echo "  -r, --remove      Remove packages"
    echo "  -h, --help        Display this help message"
}

# Check if no arguments are provided
if [ "$#" -eq 0 ]; then
    display_help
    exit 0
fi

# Parse command-line options
action="add"  # default action

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -a|--add)
            action="add"
            shift
            ;;
        -r|--remove)
            action="remove"
            shift
            ;;
        -h|--help)
            display_help
            exit 0
            ;;
        *)
            packages+=("$1")
            shift
            ;;
    esac
done

# Determine if the script is running as root
if [ "$EUID" -eq 0 ]; then
    # Ensure the system packages file exists
    if [ ! -f "$SYSTEM_PACKAGES" ]; then
        echo -e "{ pkgs, ... }:\n{\n  environment.systemPackages = with pkgs; [\n    # write packages here (dynamically, no overwriting.)\n  ];\n}" > "$SYSTEM_PACKAGES"
    fi

    # Perform the chosen action on system configuration
    for package in "${packages[@]}"; do
        if [ "$action" == "add" ]; then
            add_system_package "$package"
        elif [ "$action" == "remove" ]; then
            remove_system_package "$package"
        fi
    done

    # Prompt for importing packages.nix
    prompt_for_import "$SYSTEM_CONFIG" "$SYSTEM_PACKAGES"

else
    # Ensure the user packages file exists
    if [ ! -f "$USER_PACKAGES" ]; then
        mkdir -p "$(dirname "$USER_PACKAGES")"
        echo -e "{ pkgs, ... }:\n{\n  home.packages = with pkgs; [\n    # same thing, write packages to here, no overwriting, dynamically.\n  ];\n}" > "$USER_PACKAGES"
    fi

    # Perform the chosen action on user configuration
    for package in "${packages[@]}"; do
        if [ "$action" == "add" ]; then
            add_user_package "$package"
        elif [ "$action" == "remove" ]; then
            remove_user_package "$package"
        fi
    done

    # Prompt for importing packages.nix
    prompt_for_import "$USER_CONFIG" "$USER_PACKAGES"

fi

# Prompt for rebuild
prompt_for_rebuild

