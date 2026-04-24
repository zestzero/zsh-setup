# zsh-setup

An interactive shell script that sets up a modern Zsh environment in one command.

## What it installs

| Component | Description |
|---|---|
| [zsh](https://www.zsh.org/) | The Z shell |
| [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) | Framework for managing Zsh configuration |
| [Powerlevel10k](https://github.com/romkatv/powerlevel10k) | Fast, flexible Zsh theme |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-like autosuggestions for Zsh |

## Usage

```bash
# Interactive — each step asks for confirmation
bash setup.sh

# Non-interactive — accept every prompt automatically
bash setup.sh --yes
```

Or make the script executable first:

```bash
chmod +x setup.sh
./setup.sh
```

### What it does, step by step

1. **Install zsh** — uses the system package manager (`apt-get`, `brew`, `yum`, `dnf`, `pacman`, or `zypper`).
2. **Set default shell** — runs `chsh -s $(which zsh)`.
3. **Install Oh My Zsh** — downloads and runs the official installer with `RUNZSH=no CHSH=no` to avoid starting a new shell mid-script.
4. **Install Powerlevel10k** — clones the repo into `$ZSH_CUSTOM/themes` and updates `ZSH_THEME` in `~/.zshrc`.
5. **Install zsh-autosuggestions** — clones the repo into `$ZSH_CUSTOM/plugins` and adds the plugin to the `plugins=(…)` list in `~/.zshrc`.

Each step is skipped automatically if the component is already present, making the script safe to re-run.

## Extending the script

The script is designed to be easy to extend. To add a new plugin or tool:

1. Write a function using the skeleton provided near the bottom of `setup.sh`.
2. Call that function inside `main()`, after the existing calls.

```bash
# Example: add a new plugin
install_zsh_syntax_highlighting() {
  print_step "Step 6 · Install zsh-syntax-highlighting plugin"
  local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [ -d "$plugin_dir" ]; then
    echo "✔ zsh-syntax-highlighting is already installed."
  elif ask "Install zsh-syntax-highlighting?"; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir"
  fi
}
```

## Requirements

- `bash` 4+ (the script is written in bash so it works before zsh is installed)
- `curl` or `wget` (for Oh My Zsh)
- `git` (for Powerlevel10k and zsh-autosuggestions)
- A supported package manager for installing zsh (`apt-get`, `brew`, `yum`, `dnf`, `pacman`, or `zypper`)

## License

MIT