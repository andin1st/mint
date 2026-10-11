# i3 Keybindings & Shortcuts

**Modifier keys**
- `Super` = the Windows key = `$mod`
- `Alt` = `$alt` (used for vim-style focus: h/j/k/l)

> Tip: `Super+Shift+R` restarts i3, `Super+Shift+C` reloads the config.

---

## Launching programs

| Shortcut | Action |
|---|---|
| `Super+Space` | App launcher (rofi — apps) |
| `Super+d` | App launcher (rofi — apps) |
| `Super+Shift+d` | Run command (rofi — run) |
| `Super+Tab` | Window switcher (rofi — window) |
| `Super+Return` | Terminal — Alacritty |
| `Super+Ctrl+Return` | Terminal — Xfce4 Terminal |
| `Super+Shift+Return` | Web browser — Firefox |
| `Super+Shift+f` | File manager — Thunar |

## Window management

| Shortcut | Action |
|---|---|
| `Super+w` / `Super+q` | Close (kill) focused window |
| `Super+f` | Toggle fullscreen |
| `Super+Shift+Space` | Toggle floating / tiling |
| `Super+Alt+Space` | Toggle focus between tiling/floating |
| `Super+a` | Focus parent container |
| `Super+b` | Split horizontally |
| `Super+v` | Split vertically |
| `Super+e` | Toggle split layout |
| `Super+s` | Stacking layout |
| `Super+Shift+w` | Tabbed layout |
| `Super` + drag (mouse) | Move/​resize floating window |

## Focus & moving windows

| Shortcut | Action |
|---|---|
| `Super+← / ↓ / ↑ / →` | Focus left / down / up / right |
| `Alt+h / j / k / l` | Focus left / down / up / right (vim-style) |
| `Super+Shift+← / ↓ / ↑ / →` | Move window left / down / up / right |
| `Super+Shift+h / j / k / l` | Move window left / down / up / right |

## Workspaces

| Shortcut | Action |
|---|---|
| `Super+1` … `Super+0` | Switch to workspace 1 … 10 |
| `Super+Shift+1` … `Super+Shift+0` | Move focused window to workspace 1 … 10 |

## Resize mode

| Shortcut | Action |
|---|---|
| `Super+r` | Enter resize mode |
| `← / →` or `h / l` | Shrink / grow width |
| `↑ / ↓` or `k / j` | Shrink / grow height |
| `Return` or `Escape` | Exit resize mode |

## Lock / power / screenshots

| Shortcut | Action |
|---|---|
| `Super+Escape` | Lock screen (light-locker) |
| `Super+Shift+x` | Power menu (Lock / Suspend / Log out / Reboot / Shut down) |
| `Print` | Screenshot — full screen |
| `Super+Print` | Screenshot — region |
| `Super+Ctrl+Print` | **Extract text (OCR)** from a region → clipboard (Omarchy-style) |
| `Super+Ctrl+Shift+Print` | Extract text (OCR) from the **whole screen** |

## Wallpaper & transparency

| Shortcut | Action |
|---|---|
| `Super+Ctrl+w` | Pick wallpaper (rofi) |
| `Super+Ctrl+Shift+w` | Random wallpaper |
| `Super+Ctrl+t` | Toggle transparency of focused window |
| `Super+Ctrl+Shift+t` | Toggle transparency for ALL windows (global) |
| `Super+Ctrl+↑` | Focused window +5% opacity (less transparent) |
| `Super+Ctrl+↓` | Focused window −5% opacity (more transparent) |
| `Super+Ctrl+r` | Reset opacity on ALL windows (fully opaque) |

## Media / hardware keys

| Key | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume −5% |
| `XF86AudioMute` | Mute toggle |
| `XF86AudioMicMute` | Microphone mute toggle |

*(Brightness keys are commented out in the config — install `brightnessctl` to enable them.)*

## i3 itself

| Shortcut | Action |
|---|---|
| `Super+Shift+c` | Reload i3 config |
| `Super+Shift+r` | Restart i3 in place |
| `Super+Shift+e` | Exit i3 (with confirmation) |

---

## Shell (zsh + Oh My Zsh + Powerlevel10k)

| Key / command | Action |
|---|---|
| `Ctrl+r` | Reverse-search command history (fzf-like) |
| `↑ / ↓` | History search by prefix |
| `→` or `End` | Accept the greyed-out autosuggestion |
| `z <dir>` | Jump to a frequently used directory (z plugin) |
| `Esc Esc` | Prepend `sudo` to the current command (sudo plugin) |
| `x <archive>` | Extract almost any archive (extract plugin) |
| `p10k configure` | Re-run the Powerlevel10k prompt wizard |

**Prompt:** Powerlevel10k "lean" style with a **compact git segment** — it shows the branch (green) plus a single yellow `±` when the repo is dirty.

> Note: running `p10k configure` regenerates `~/.p10k.zsh` and will drop the compact-git tweak. Re-apply with `bash ~/i3-mint-setup/setup.sh --p10k-only` (or just re-run the whole script).
