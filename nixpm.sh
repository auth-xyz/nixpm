#!/bin/sh

# Define paths for system-wide and user-specific configurations
SYSTEM_CONFIG="/etc/nixos/configuration.nix"
SYSTEM_PACKAGES="/etc/nixos/packages.nix"
USER_CONFIG="$HOME/.config/home-manager/home.nix"
USER_PACKAGES="$HOME/.config/home-manager/packages.nix"

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() { echo -e "${GREEN}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }
print_warning() { echo -e "${YELLOW}$1${NC}"; }

# Validate package name
validate_package_name() {
    package_name="$1"
    if [ -z "$package_name" ]; then
        print_error "Package name cannot be empty."
        exit 1
    fi
}

# Create a backup of the given file
backup_file() {
    file_path="$1"
    cp "$file_path" "${file_path}.bak" || { print_error "Failed to backup $file_path"; exit 1; }
}

# Function to add a package to a config file
add_package() {
    package_name=$1
    config_file=$2
    match_line=$3

    validate_package_name "$package_name"

    if grep -q "\b$package_name\b" "$config_file"; then
        print_warning "$package_name is already in the configuration."
    else
        backup_file "$config_file"
        sed -i "/$match_line/a \    $package_name" "$config_file"
        print_success "Added $package_name to the configuration."
    fi
}

# Function to remove a package from a config file
remove_package() {
    package_name=$1
    config_file=$2

    validate_package_name "$package_name"

    if grep -q "\b$package_name\b" "$config_file"; then
        backup_file "$config_file"
        sed -i "/\b$package_name\b/d" "$config_file"
        print_success "Removed $package_name from the configuration."
    else
        print_warning "$package_name is not in the configuration."
    fi
}

# Function to prompt for importing packages.nix
prompt_for_import() {
    config_file=$1
    packages_file=$2

    if grep -q "\./packages.nix" "$config_file"; then
        print_warning "packages.nix is already imported in $config_file."
    else
        read -p "Would you like to import packages.nix into $config_file? (y/n): " import_response
        if [[ "$import_response" =~ ^[Yy]$ ]]; then
            backup_file "$config_file"
            sed -i "/imports = \[/a \  ./packages.nix" "$config_file"
            print_success "Imported packages.nix into $config_file."
        fi
    fi
}

# Centralized function for rebuild
perform_rebuild() {
    if [ "$EUID" -eq 0 ]; then
        read -p "Would you like to run 'sudo nixos-rebuild switch'? (y/n): " rebuild_response
        if [[ "$rebuild_response" =~ ^[Yy]$ ]]; then
            sudo nixos-rebuild switch || { print_error "Failed to rebuild system."; exit 1; }
            print_success "System rebuild successful."
        fi
    else
        read -p "Would you like to run 'home-manager switch'? (y/n): " rebuild_response
        if [[ "$rebuild_response" =~ ^[Yy]$ ]]; then
            home-manager switch || { print_error "Failed to rebuild home-manager."; exit 1; }
            print_success "Home-manager rebuild successful."
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
    [ ! -f "$SYSTEM_PACKAGES" ] && echo -e "{ pkgs, ... }:\n{\n  environment.systemPackages = with pkgs; [\n    # write packages here\n  ];\n}" > "$SYSTEM_PACKAGES"
    for package in "${packages[@]}"; do
        if [ "$action" == "add" ]; then
            add_package "$package" "$SYSTEM_PACKAGES" "environment.systemPackages = with pkgs;"
        elif [ "$action" == "remove" ]; then
            remove_package "$package" "$SYSTEM_PACKAGES"
        fi
    done
    prompt_for_import "$SYSTEM_CONFIG" "$SYSTEM_PACKAGES"
else
    [ ! -f "$USER_PACKAGES" ] && mkdir -p "$(dirname "$USER_PACKAGES")" && echo -e "{ pkgs, ... }:\n{\n  home.packages = with pkgs; [\n    # write packages here\n  ];\n}" > "$USER_PACKAGES"
    for package in "${packages[@]}"; do
        if [ "$action" == "add" ]; then
            add_package "$package" "$USER_PACKAGES" "home.packages = with pkgs;"
        elif [ "$action" == "remove" ]; then
            remove_package "$package" "$USER_PACKAGES"
        fi
    done
    prompt_for_import "$USER_CONFIG" "$USER_PACKAGES"
fi

perform_rebuild

