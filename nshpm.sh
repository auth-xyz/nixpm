#!/bin/sh

# Define paths for default.nix and shell.nix files in the current directory
DEFAULT_NIX="./default.nix"
SHELL_NIX="./shell.nix"

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

# Function to delete the .bak file after a successful modification
delete_backup() {
    backup_file="$1.bak"
    if [ -f "$backup_file" ]; then
        rm "$backup_file" && print_success "Backup file $backup_file deleted."
    else
        print_warning "No backup file $backup_file found."
    fi
}

# Function to add a package to a nix file
add_package() {
    package_name=$1
    nix_file=$2
    match_line=$3

    validate_package_name "$package_name"

    if grep -q "\b$package_name\b" "$nix_file"; then
        print_warning "$package_name is already in the configuration."
    else
        backup_file "$nix_file"
        sed -i "/$match_line/a \    $package_name" "$nix_file"
        print_success "Added $package_name to $nix_file."
    fi
}

# Function to remove a package from a nix file
remove_package() {
    package_name=$1
    nix_file=$2

    validate_package_name "$package_name"

    if grep -q "\b$package_name\b" "$nix_file"; then
        backup_file "$nix_file"
        sed -i "/\b$package_name\b/d" "$nix_file"
        print_success "Removed $package_name from $nix_file."
    else
        print_warning "$package_name is not in the configuration."
    fi
}

# Function to prompt the user to create default.nix or shell.nix if not present
create_nix_file() {
    nix_file=$1
    if [ ! -f "$nix_file" ]; then
        read -p "$nix_file not found. Would you like to create it? (y/n): " create_response
        if [[ "$create_response" =~ ^[Yy]$ ]]; then
            backup_file "$nix_file"
            echo -e "{ pkgs ? import <nixpkgs> {} }:\n\n{\n  buildInputs = with pkgs; [\n    # add packages here\n  ];\n}" > "$nix_file"
            print_success "$nix_file created."
        else
            print_error "No $nix_file found, and user chose not to create it. Exiting."
            exit 1
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
nix_file=""

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
        -f|--file)
            nix_file="$2"
            shift 2
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

# Use default.nix or shell.nix, if specified
if [ -z "$nix_file" ]; then
    if [ -f "$DEFAULT_NIX" ]; then
        nix_file="$DEFAULT_NIX"
    elif [ -f "$SHELL_NIX" ]; then
        nix_file="$SHELL_NIX"
    else
        nix_file="$DEFAULT_NIX"  # Default to default.nix if both are missing
    fi
fi

# Ensure the file exists or create one
create_nix_file "$nix_file"

# Process the packages based on the selected action
for package in "${packages[@]}"; do
    if [ "$action" == "add" ]; then
        add_package "$package" "$nix_file" "buildInputs = with pkgs;"
    elif [ "$action" == "remove" ]; then
        remove_package "$package" "$nix_file"
    fi
done

print_success "Package operations complete."

