#!/usr/bin/env bash
set -e  # exit if any command fails
set -u  # treat unset variables as errors

# Your home and Dotfiles directories
DOTFILES="$HOME/Dotfiles"
CONFIG="$HOME/.config"

echo "Starting Dotfiles setup..."

# Ensure Dotfiles directory exists
mkdir -p "$DOTFILES"

# List of apps to symlink
apps=("hypr" "kitty")

for app in "${apps[@]}"; do
    if [ -e "$CONFIG/$app" ] && [ ! -L "$CONFIG/$app" ]; then
        echo "Moving existing $app config into Dotfiles..."
        mv "$CONFIG/$app" "$DOTFILES/$app"
    fi

    # Remove existing symlink if any
    if [ -L "$CONFIG/$app" ]; then
        echo "Removing old symlink $CONFIG/$app"
        rm "$CONFIG/$app"
    fi

    # Create symlink
    echo "Creating symlink for $app..."
    ln -s "$DOTFILES/$app" "$CONFIG/$app"
done

echo "Dotfiles setup complete!"
