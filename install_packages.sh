#!/bin/bash

# install.sh - Complete setup script for Dotfiles
# This script installs all packages and sets up symlinks for dotfiles

set -e  # Exit on error
set -u  # Treat unset variables as errors

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root"
    exit 1
fi

# Your home and Dotfiles directories
DOTFILES="$HOME/Dotfiles"
CONFIG="$HOME/.config"

# ============================================================================
# PART 1: PACKAGE INSTALLATION
# ============================================================================

print_status "Starting package installation..."

# Update system first
print_status "Updating system packages..."
sudo pacman -Syu --noconfirm

# Install base-devel and git if not present (required for yay)
print_status "Installing base-devel and git..."
sudo pacman -S --needed --noconfirm base-devel git

# Check and install yay if not present
if ! command -v yay &> /dev/null; then
    print_status "yay not found. Installing yay from AUR..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
    print_success "yay installed successfully"
else
    print_status "yay is already installed"
fi

# Array of packages to install via pacman
PACMAN_PACKAGES=(
    "tree"           # Directory tree viewer
    "github-cli"     # GitHub CLI tool
    "exa"            # Modern ls replacement
    "fastfetch"      # System information display
    "sbctl"          # Secure boot management
    "hyprland"       # Wayland compositor
    "kitty"          # Terminal emulator
    "swww"           # Wallpaper daemon
    "hyprpaper"      # Wallpaper utility for Hyprland
    "rofi"           # Application launcher
    "waybar"         # Status bar
    "swaync"         # Notification daemon
    "man"            # Manual pages
    "xdg-user-dirs"  # User directories management
    "zsh" 		#Zshell
)

# Array of packages to install via yay (AUR)
YAY_PACKAGES=(
    "visual-studio-code-bin" # Visual Studio Code
)

# Install pacman packages
print_status "Installing packages from official repositories..."
for package in "${PACMAN_PACKAGES[@]}"; do
    print_status "Installing $package..."
    if sudo pacman -S --needed --noconfirm "$package"; then
        print_success "$package installed successfully"
    else
        print_error "Failed to install $package"
    fi
done

# Install yay packages
print_status "Installing packages from AUR..."
for package in "${YAY_PACKAGES[@]}"; do
    print_status "Installing $package from AUR..."
    if yay -S --needed --noconfirm "$package"; then
        print_success "$package installed successfully"
    else
        print_error "Failed to install $package from AUR"
    fi
done

# Create basic directories if they don't exist
print_status "Creating user directories..."
xdg-user-dirs-update

print_success "Package installation complete!"

# ============================================================================
# PART 2: OH-MY-ZSH AND POWERLEVEL10K SETUP
# ============================================================================

# Optional: Install Oh My Zsh and Powerlevel10k
print_warning "Do you want to set up/update Oh My Zsh and Powerlevel10k? (y/n)"
read -r install_zsh
if [[ "$install_zsh" =~ ^[Yy]$ ]]; then
    # Check if Oh My Zsh is already installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_status "Oh My Zsh is already installed at $HOME/.oh-my-zsh"
        print_warning "Do you want to:"
        echo "1) Keep existing installation and just install/update Powerlevel10k"
        echo "2) Reinstall Oh My Zsh (backup existing configuration)"
        echo "3) Skip Oh My Zsh setup"
        read -r zsh_choice
        
        case $zsh_choice in
            1)
                print_status "Keeping existing Oh My Zsh installation..."
                ;;
            2)
                print_status "Backing up existing Oh My Zsh configuration..."
                backup_dir="$HOME/ohmyzsh-backup-$(date +%Y%m%d-%H%M%S)"
                mv "$HOME/.oh-my-zsh" "$backup_dir"
                if [ -f "$HOME/.zshrc" ]; then
                    cp "$HOME/.zshrc" "$backup_dir/"
                fi
                print_success "Backed up to $backup_dir"
                
                print_status "Installing Oh My Zsh..."
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
                ;;
            3)
                print_status "Skipping Oh My Zsh installation..."
                ;;
        esac
    else
        print_status "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Install/Update Powerlevel10k theme
    print_status "Setting up Powerlevel10k theme..."
    p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    
    if [ -d "$p10k_dir" ]; then
        print_status "Powerlevel10k already exists, updating..."
        (cd "$p10k_dir" && git pull)
    else
        print_status "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    fi
    
    # Check if .zshrc exists and update theme if needed
    if [ -f "$HOME/.zshrc" ]; then
        # Backup .zshrc
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
        
        if grep -q "ZSH_THEME=" "$HOME/.zshrc"; then
            # Update existing theme
            sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
        else
            # Add theme if not present
            echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
        fi
        print_success "Updated ZSH_THEME in .zshrc"
    fi
    
    # Check for existing Powerlevel10k configuration
    if [ -f "$HOME/.p10k.zsh" ]; then
        print_status "Found existing Powerlevel10k configuration at $HOME/.p10k.zsh"
        print_warning "Do you want to keep this configuration? (y/n)"
        read -r keep_p10k_config
        if [[ "$keep_p10k_config" =~ ^[Yy]$ ]]; then
            print_success "Keeping existing Powerlevel10k configuration"
        else
            print_warning "Configuration will be regenerated on next terminal start"
        fi
    fi
    
    print_success "Oh My Zsh and Powerlevel10k setup complete"
    print_warning "You may need to restart your terminal or run 'source ~/.zshrc' to apply changes"
fi

# ============================================================================
# PART 3: DOTFILES SYMLINK SETUP
# ============================================================================

print_status "Starting Dotfiles symlink setup..."

# Ensure Dotfiles directory exists
mkdir -p "$DOTFILES"

# List of config directories to symlink
apps=("hypr" "kitty" "rofi" "waybar" "swaync")

for app in "${apps[@]}"; do
    # Check if the app directory exists in Dotfiles
    if [ -d "$DOTFILES/$app" ]; then
        print_status "Setting up symlink for $app..."
        
        # Handle existing config in .config
        if [ -e "$CONFIG/$app" ]; then
            if [ ! -L "$CONFIG/$app" ]; then
                # It's a regular directory/file, not a symlink
                print_warning "Found existing $app config at $CONFIG/$app"
                print_warning "Moving to $DOTFILES/$app (backup created)"
                mv "$CONFIG/$app" "$DOTFILES/$app.bak.$(date +%Y%m%d-%H%M%S)"
            else
                # It's an existing symlink, remove it
                print_warning "Removing old symlink $CONFIG/$app"
                rm "$CONFIG/$app"
            fi
        fi
        
        # Create the symlink
        ln -s "$DOTFILES/$app" "$CONFIG/$app"
        print_success "Created symlink for $app"
    else
        print_warning "Directory $DOTFILES/$app not found. Skipping..."
    fi
done

# Symlink home dotfiles
HOME_DOTFILES=(".zshrc" ".p10k.zsh" ".bashrc")
for file in "${HOME_DOTFILES[@]}"; do
    if [ -f "$DOTFILES/$file" ]; then
        print_status "Setting up symlink for $file..."
        if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
            print_warning "Backing up existing $HOME/$file to $HOME/$file.backup"
            mv "$HOME/$file" "$HOME/$file.backup"
        fi
        if [ -L "$HOME/$file" ]; then
            rm "$HOME/$file"
        fi
        ln -s "$DOTFILES/$file" "$HOME/$file"
        print_success "Created symlink for $file"
    fi
done

print_success "Dotfiles symlink setup complete!"

# ============================================================================
# PART 4: FINAL TOUCHES
# ============================================================================

# Check if we're on Hyprland and offer to reload
if [ "$XDG_SESSION_DESKTOP" = "hyprland" ]; then
    print_warning "Do you want to reload Hyprland configuration? (y/n)"
    read -r reload_hypr
    if [[ "$reload_hypr" =~ ^[Yy]$ ]]; then
        hyprctl reload
        print_success "Hyprland reloaded"
    fi
fi

# Final summary
print_success "======================================"
print_success "Setup completed successfully!"
print_success "======================================"
print_status "Installed packages:"
echo -e "${GREEN}Official repositories:${NC} ${PACMAN_PACKAGES[*]}"
echo -e "${GREEN}AUR packages:${NC} ${YAY_PACKAGES[*]}"
echo ""
print_status "Symlinks created for: ${apps[*]} and ${HOME_DOTFILES[*]}"
echo ""
print_warning "Next steps:"
echo "  1. Restart your terminal or run 'source ~/.zshrc' to apply Zsh changes"
echo "  2. If you're using Powerlevel10k for the first time, it will prompt for configuration"
echo "  3. Run 'p10k configure' if you want to reconfigure Powerlevel10k"
echo "  4. Review your config files in ~/.config/ to ensure everything works"
