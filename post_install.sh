#!/bin/bash

# Innan gör manuellt
# Skapat Arch ISO på USB
# Installerat Arch på 200 GB ext4 (dualboot med Windows)
# Fått GRUB att visa Windows via os-prober
# Konfigurerat tid, locale, sudo, hostname, NetworkManager
# Reboot till fungerande Arch-system
# Fixat svensk tangentbordslayout i terminal

set -e  # Exit on error
echo "🚀 Starting post-install setup..."

# 1. Update system
echo "🔄 Updating system..."
sudo pacman -Syu --noconfirm

# 2. Install base CLI packages
echo "📦 Installing CLI tools..."
sudo pacman -S --noconfirm base-devel git curl zsh neovim bat exa htop starship

# 3. Install rustup and stable Rust (for cargo support)
echo "🦀 Installing Rust toolchain..."
sudo pacman -S --noconfirm rustup
rustup install stable
rustup default stable

# 4. Setup ZSH as default shell
echo "💻 Setting ZSH as default shell..."
chsh -s /bin/zsh

# 5. Install paru (AUR helper)
echo "📦 Installing paru from AUR..."
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru
makepkg -si --noconfirm
cd ~
rm -rf /tmp/paru

# 6. Set up Starship prompt
echo "✨ Setting up Starship prompt..."
echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# 7. Install ZSH plugins
echo "🔌 Installing ZSH plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting

# Add plugins to .zshrc if not already added
touch ~/.zshrc
grep -qxF 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' ~/.zshrc || echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
grep -qxF 'source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' ~/.zshrc || echo 'source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> ~/.zshrc

# 8. Bind Tab to accept autosuggestions
echo "🔧 Setting Tab key to accept autosuggestions..."
grep -qxF 'bindkey "^]" autosuggest-accept' ~/.zshrc || echo 'bindkey "^]" autosuggest-accept' >> ~/.zshrc

# 9. Add aliases and history/completion tweaks
if ! grep -q "alias ls='exa --icons'" ~/.zshrc; then
  echo "🔧 Adding ZSH aliases and options..."
  cat << 'EOF' >> ~/.zshrc

# === Custom Aliases ===
alias ls='exa --icons'
alias cat='bat'
alias grep='grep --color=auto'
alias g='git'

# === History Behavior ===
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt append_history share_history

# === Completion System ===
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
EOF
fi

# 10. Install Hyprland and core Wayland tools
echo "🧱 Installing Hyprland environment..."
paru -S --noconfirm \
  hyprland waybar rofi mako swww kitty \
  xdg-desktop-portal-hyprland xdg-desktop-portal-wlr \
  qt5-wayland qt6-wayland \
  ttf-jetbrains-mono-nerd ttf-font-awesome \
  grim slurp wl-clipboard

# 11. Install and enable SDDM display manager
echo "🖥️ Installing SDDM (display manager)..."
paru -S --noconfirm sddm
sudo systemctl enable sddm.service

# 12. Install image to show as wallpaper
mkdir -p ~/Pictures/wallpapers
curl -o ~/Pictures/wallpapers/default.jpg https://picsum.photos/1920/1080


# 13. Create basic Hyprland config folder
echo "🛠️ Creating Hyprland config structure..."
mkdir -p ~/.config/hypr
touch ~/.config/hypr/hyprland.conf

# 14. Write Hyprland configuration
echo "📝 Writing Hyprland configuration..."
cat << 'EOF' > ~/.config/hypr/hyprland.conf
# === Input ===
input {
  kb_layout = se
  follow_mouse = 1
  sensitivity = 0.0
}

# === Monitor ===
monitor = eDP-1, preferred, auto, 1.0

# === General settings ===
general {
  gaps_in = 5
  gaps_out = 10
  border_size = 2
  col.active_border = rgba(89b4faee)
  col.inactive_border = rgba(313244aa)
  layout = dwindle
}

# === Animations ===
animations {
  enabled = yes
  bezier = myBezier, 0.05, 0.9, 0.1, 1.05
  animation = windows, 1, 7, myBezier
  animation = fade, 1, 7, default
  animation = border, 1, 10, default
  animation = workspaces, 1, 6, default
}

# === Window rules ===
windowrulev2 = float, title:^(Rofi)$
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = opacity 0.95 0.95, class:^(kitty)$

# === Autostart ===
exec-once = swww init
exec-once = swww img ~/Pictures/wallpapers/default.jpg
exec-once = waybar
exec-once = mako
exec-once = hyprctl setcursor Bibata-Modern-Ice 24
exec-once = setxkbmap -option caps:escape

# === Keybinds (Super = Mac Command) ===
$mod = SUPER

bind = $mod, RETURN, exec, kitty
bind = $mod, Q, killactive,
bind = $mod, SPACE, exec, rofi -show drun
bind = $mod SHIFT, E, exit,

# Move focus
bind = $mod, H, movefocus, l
bind = $mod, L, movefocus, r
bind = $mod, K, movefocus, u
bind = $mod, J, movefocus, d

# Move window
bind = $mod SHIFT, H, movewindow, l
bind = $mod SHIFT, L, movewindow, r
bind = $mod SHIFT, K, movewindow, u
bind = $mod SHIFT, J, movewindow, d

# Workspaces
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5

# Screenshot
bind = $mod, P, exec, grim -g "$(slurp)" - | wl-copy
EOF

# 15. Create custom Waybar config
echo "🎨 Creating Waybar config and style..."
mkdir -p ~/.config/waybar

# Waybar config (JSONC-style)
cat << 'EOF' > ~/.config/waybar/config.jsonc
{
  "layer": "top",
  "position": "top",
  "height": 28,
  "modules-left": ["hyprland/workspaces"],
  "modules-center": ["clock"],
  "modules-right": ["cpu", "memory", "pulseaudio", "network", "uptime"],

  "clock": {
    "format": "{:%a %d %b  %H:%M}"
  },
  "cpu": {
    "format": "  {usage}%",
    "tooltip": false
  },
  "memory": {
    "format": "  {used:0.1f}G",
    "tooltip": false
  },
  "pulseaudio": {
    "format": "  {volume}%",
    "tooltip": false,
    "format-muted": "  muted"
  },
  "network": {
    "format-wifi": "  {essid}",
    "format-ethernet": "󰈀  {ipaddr}",
    "tooltip": false,
    "format-disconnected": "Disconnected"
  },
  "uptime": {
    "format": "󰔟  {days}d {hours}h"
  }
}
EOF

# Waybar styling
cat << 'EOF' > ~/.config/waybar/style.css
* {
  font-family: 'JetBrainsMono Nerd Font', monospace;
  font-size: 13px;
  border: none;
  border-radius: 0px;
  padding: 0 8px;
}

window#waybar {
  background-color: #1e1e2e;
  color: #cdd6f4;
}

#workspaces button {
  padding: 0 6px;
  color: #a6adc8;
  background: transparent;
  border-bottom: 2px solid transparent;
}

#workspaces button.active {
  color: #89b4fa;
  border-bottom: 2px solid #89b4fa;
}

#clock, #cpu, #memory, #pulseaudio, #network, #uptime {
  background-color: #313244;
  margin: 0 4px;
  padding: 2px 8px;
  border-radius: 6px;
}
EOF

# 16. Install GUI utility apps and cursor
echo "🧩 Installing GUI utilities and theme tools..."
paru -S --noconfirm lxappearance bibata-cursor-theme \
  pavucontrol brightnessctl network-manager-applet

# Set default cursor theme (already in Hypr config via hyprctl)
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice"
