#!/usr/bin/env bash
# setup.sh — Interactive Zsh environment setup script
#
# Installs and configures:
#   1. zsh
#   2. Oh My Zsh  (https://github.com/ohmyzsh/ohmyzsh)
#   3. Powerlevel10k theme  (https://github.com/romkatv/powerlevel10k)
#   4. zsh-autosuggestions plugin  (https://github.com/zsh-users/zsh-autosuggestions)
#
# Usage:
#   bash setup.sh          # run all steps interactively
#   bash setup.sh --yes    # non-interactive: accept every prompt automatically
#
# How to add a new step:
#   1. Write a function following the pattern of the existing step functions.
#   2. Append a call to that function inside main() below the existing calls.
#
# The script is intentionally written in bash (not zsh) so that it can run
# before zsh is installed.

set -euo pipefail

# ---------------------------------------------------------------------------
# Global flags
# ---------------------------------------------------------------------------

AUTO_YES=false

for arg in "$@"; do
  case "$arg" in
    --yes|-y) AUTO_YES=true ;;
  esac
done

# ---------------------------------------------------------------------------
# Utility helpers
# ---------------------------------------------------------------------------

# Print a highlighted step header.
print_step() {
  echo ""
  echo "──────────────────────────────────────────"
  echo "  $1"
  echo "──────────────────────────────────────────"
}

# Ask a yes/no question; returns 0 (true) when the answer is yes.
# Automatically answers "yes" when AUTO_YES is set.
ask() {
  local prompt="$1"
  local response

  if $AUTO_YES; then
    echo "$prompt [Y/n] y (auto)"
    return 0
  fi

  while true; do
    read -r -p "$prompt [Y/n] " response
    response="${response:-y}"
    case "$response" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

# Return 0 if $1 is available on PATH.
command_exists() {
  command -v "$1" &>/dev/null
}

# Install a package using whichever package manager is available.
install_package() {
  local package="$1"
  if command_exists apt-get; then
    sudo apt-get update -qq && sudo apt-get install -y "$package"
  elif command_exists brew; then
    brew install "$package"
  elif command_exists yum; then
    sudo yum install -y "$package"
  elif command_exists dnf; then
    sudo dnf install -y "$package"
  elif command_exists pacman; then
    sudo pacman -S --noconfirm "$package"
  elif command_exists zypper; then
    sudo zypper install -y "$package"
  else
    echo "ERROR: No supported package manager found. Please install '$package' manually." >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Step 1 — Install zsh
# ---------------------------------------------------------------------------

install_zsh() {
  print_step "Step 1 · Install zsh"

  if command_exists zsh; then
    echo "✔ zsh is already installed: $(zsh --version)"
    return
  fi

  if ask "zsh is not installed. Install it now?"; then
    install_package zsh
    echo "✔ zsh installed: $(zsh --version)"
  else
    echo "Skipped. zsh is required for the remaining steps." >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Step 2 — Set zsh as the default shell
# ---------------------------------------------------------------------------

set_default_shell() {
  print_step "Step 2 · Set zsh as the default shell"

  local zsh_path
  zsh_path="$(command -v zsh)"

  if [ "$SHELL" = "$zsh_path" ]; then
    echo "✔ zsh is already your default shell."
    return
  fi

  if ask "Set zsh as your default shell? (runs: chsh -s $zsh_path)"; then
    # Ensure zsh is listed in /etc/shells before calling chsh.
    if ! grep -qx "$zsh_path" /etc/shells; then
      echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    fi
    chsh -s "$zsh_path"
    echo "✔ Default shell set to zsh. Restart your terminal to apply."
  else
    echo "Skipped setting default shell."
  fi
}

# ---------------------------------------------------------------------------
# Step 3 — Install Oh My Zsh
# ---------------------------------------------------------------------------

install_oh_my_zsh() {
  print_step "Step 3 · Install Oh My Zsh"

  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "✔ Oh My Zsh is already installed."
    return
  fi

  if ! command_exists curl && ! command_exists wget; then
    echo "ERROR: curl or wget is required to install Oh My Zsh." >&2
    exit 1
  fi

  if ask "Install Oh My Zsh?"; then
    # RUNZSH=no  — do not start a new zsh session after install
    # CHSH=no    — do not change the default shell here (handled in step 2)
    RUNZSH=no CHSH=no \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo "✔ Oh My Zsh installed."
  else
    echo "Skipped Oh My Zsh installation."
  fi
}

# ---------------------------------------------------------------------------
# Step 4 — Install Powerlevel10k theme
# ---------------------------------------------------------------------------

install_powerlevel10k() {
  print_step "Step 4 · Install Powerlevel10k theme"

  local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

  if [ -d "$theme_dir" ]; then
    echo "✔ Powerlevel10k is already installed."
  elif ask "Install Powerlevel10k theme?"; then
    if ! command_exists git; then
      echo "ERROR: git is required to install Powerlevel10k." >&2
      exit 1
    fi
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
    echo "✔ Powerlevel10k installed."
  else
    echo "Skipped Powerlevel10k installation."
    return
  fi

  # Update ZSH_THEME in ~/.zshrc if the file exists.
  if [ -f "$HOME/.zshrc" ]; then
    if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
      sed -i.bak 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc" \
        && rm -f "$HOME/.zshrc.bak"
      echo "✔ ZSH_THEME set to powerlevel10k/powerlevel10k in ~/.zshrc"
    else
      echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
      echo "✔ ZSH_THEME added to ~/.zshrc"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Step 5 — Install zsh-autosuggestions plugin
# ---------------------------------------------------------------------------

install_zsh_autosuggestions() {
  print_step "Step 5 · Install zsh-autosuggestions plugin"

  local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

  if [ -d "$plugin_dir" ]; then
    echo "✔ zsh-autosuggestions is already installed."
  elif ask "Install zsh-autosuggestions?"; then
    if ! command_exists git; then
      echo "ERROR: git is required to install zsh-autosuggestions." >&2
      exit 1
    fi
    git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"
    echo "✔ zsh-autosuggestions installed."
  else
    echo "Skipped zsh-autosuggestions installation."
    return
  fi

  # Enable the plugin in ~/.zshrc if it is not already listed.
  if [ -f "$HOME/.zshrc" ] && ! grep -q 'zsh-autosuggestions' "$HOME/.zshrc"; then
    # Insert 'zsh-autosuggestions' into the plugins=(...) list.
    # This handles both single-line and the common case where each plugin is on its own line.
    if grep -q '^plugins=(' "$HOME/.zshrc"; then
      # Single-line: plugins=(git ...) → add the new plugin before the closing paren.
      sed -i.bak '/^plugins=(/ s/)$/ zsh-autosuggestions)/' "$HOME/.zshrc" \
        && rm -f "$HOME/.zshrc.bak"
    else
      # Fallback: append a standalone plugins line (e.g. when Oh My Zsh isn't installed).
      echo 'plugins=(zsh-autosuggestions)' >> "$HOME/.zshrc"
    fi
    echo "✔ zsh-autosuggestions added to plugins in ~/.zshrc"
  fi
}

# ---------------------------------------------------------------------------
# ★ ADD NEW STEPS HERE
#
# Example skeleton:
#
# install_my_plugin() {
#   print_step "Step N · My plugin"
#   local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/my-plugin"
#   if [ -d "$plugin_dir" ]; then
#     echo "✔ my-plugin is already installed."
#   elif ask "Install my-plugin?"; then
#     git clone https://github.com/user/my-plugin "$plugin_dir"
#   fi
# }
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║   Interactive Zsh Environment Setup      ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
  echo "Components to install:"
  echo "  1. zsh"
  echo "  2. Oh My Zsh"
  echo "  3. Powerlevel10k theme"
  echo "  4. zsh-autosuggestions plugin"
  echo ""
  if $AUTO_YES; then
    echo "Running in non-interactive mode (--yes flag detected)."
  fi

  install_zsh
  set_default_shell
  install_oh_my_zsh
  install_powerlevel10k
  install_zsh_autosuggestions
  # ↑ Add calls to new step functions here, in order.

  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║   Setup complete!                        ║"
  echo "║   Restart your terminal or run:          ║"
  echo "║     exec zsh                             ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
}

main "$@"
