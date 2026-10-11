# Mint i3 Setup — "Omarchy-like" desktop on Linux Mint 22.x

A reproducible i3wm desktop (launcher, browser, file manager, transparency,
wallpapers, Nerd Font bar, zsh + Powerlevel10k) layered **on top of** a stock
Linux Mint 22.3 "Zena" (Xfce) install, without touching the Xfce session.

- **OS**: Linux Mint 22.3 (Xfce), Ubuntu `noble`, X11
- **WM**: i3 4.23 (as a separate login session)
- **Compositor**: picom 10.2
- **Launcher**: rofi 1.7.5
- **Shell**: zsh 5.9 + Oh My Zsh + Powerlevel10k
- **Font**: Hack Nerd Font

The Xfce session is left intact as a fallback — pick **i3** from the session
menu at the login screen (LightDM).

---

## Files in this folder

| File | Purpose |
|---|---|
| `setup.sh` | One-shot installer/reproducer for a fresh Mint install |
| `KEYBINDINGS.md` | Full list of shortcuts/keys |
| `README.md` | This summary |

---

## What `setup.sh` does

1. Installs packages: `i3-wm i3status rofi picom feh xss-lock xautolock`,
   `alacritty`, `light-locker`, `xfce4-power-manager`, `network-manager-gnome`,
   `blueman`, `xfce4-screenshooter`, `zsh git curl wget unzip`, plus
   `x11-xserver-utils`, `pulseaudio-utils`, `flatpak`, and the OCR/capture tools
   `tesseract-ocr tesseract-ocr-eng maim slop xdotool xclip libnotify-bin`.
2. Installs **Hack Nerd Font** to `~/.local/share/fonts/HackNerdFont`.
3. Writes all config files (see inventory below) —
   auto-detects your network interfaces for the status bar.
4. Backs up any existing config to `~/.i3-mint-setup-backups/<timestamp>/`.
5. Installs the Flatpak apps **LocalSend** and **ONLYOFFICE Desktop Editors**
   (user-scoped, from Flathub).
6. Installs **Oh My Zsh** + `powerlevel10k` + `zsh-autosuggestions` +
   `zsh-syntax-highlighting`, and applies the **compact git** prompt tweak.
7. Removes Xfce's `Super`-key shortcuts (so they don't hijack i3's keybinds
   via `xfsettingsd`).
8. Sets **zsh** as your login shell.

### Usage

```bash
cd ~/i3-mint-setup
bash setup.sh
# then: log out and pick the "i3" session at the login screen
```

Run it as your **normal user** (it calls `sudo` when needed, so you'll be
prompted for your password). Re-running it is safe (idempotent).

Options:
```bash
bash setup.sh --no-packages   # skip apt install
bash setup.sh --p10k-only     # only (re)apply the Powerlevel10k config + compact git tweak
```

---

## Config inventory (what gets written)

| Path | Contents |
|---|---|
| `~/.config/i3/config` | i3 keybinds, colors, gaps, autostart, bar |
| `~/.config/i3/transparency.sh` | opacity up/down/toggle/reset/global/restart |
| `~/.config/i3/wallpaper.sh` | wallpaper pick/random/restore/list (feh) |
| `~/.config/i3/power-menu.sh` | rofi power menu (lock/suspend/logout/reboot/shutdown) |
| `~/.config/i3/screenshot-ocr.sh` | Omarchy-style screenshot → tesseract OCR → clipboard |
| `~/.config/i3status/config` | bar modules with Nerd Font icons (auto interface names) |
| `~/.config/picom/picom.conf` | 85%/80% opacity, shadows, fading, **blur disabled** |
| `~/.config/rofi/config.rasi` | rofi modi: drun, run, window |
| `~/.config/alacritty/alacritty.toml` | Hack Nerd Font Mono 11 |
| `~/.config/gtk-3.0/settings.ini` | GTK3: Mint-Y-Dark + Papirus-Dark |
| `~/.config/gtk-4.0/settings.ini` | GTK4: Mint-Y-Dark + Papirus-Dark |
| `~/.gtkrc-2.0` | GTK2: Mint-Y-Dark + Papirus-Dark |
| `~/.zshrc` | Oh My Zsh, plugins, theme, p10k source |
| `~/.p10k.zsh` | Powerlevel10k "lean" + compact git segment |

Applied via `xfconf` (for the Xfce session): `/Net/ThemeName=Mint-Y-Dark`,
`/Net/IconThemeName=Papirus-Dark`.

---

## Key design decisions / notes

- **i3 is a separate session.** Xfce is untouched and still selectable at login.
- **rofi instead of dmenu** (dmenu is not in Mint's enabled repos).
- **picom 10.2** supports blur but **not rounded corners** (needs picom 11+).
- **Blur is disabled** = "pure transparency" (no frosted/acrylic background).
  Transparency: active windows 85%, inactive 80%.
- **`xfsettingsd` runs under i3** for live GTK theme changes. Because it also
  loads Xfce's keyboard shortcuts, this script **clears Xfce's `Super`
  bindings** — otherwise grabbing the bare `Super` key would swallow every
  `Super+…` shortcut before i3 sees it.
- `i3-msg reload` does **not** restart `i3status`; use `i3-msg restart` to
  reload the bar config (plain `exec` lines only run on first start, so
  restarting doesn't duplicate the applets).
- Media/brightness: brightness keys are commented out until `brightnessctl`
  is installed.
- The status bar uses **Nerd Font glyphs**; the interfaces (`enp3s0`/`wlp2s0`
  on the original machine) are auto-detected by the installer.
