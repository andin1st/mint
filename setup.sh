#!/usr/bin/env bash
# =============================================================================
#  mint-i3-setup
#  Reproduce an i3 + "Omarchy-like" desktop on Linux Mint 22.x (Xfce, X11).
#
#  Usage : bash setup.sh [--no-packages] [--p10k-only]
#  Run as: your NORMAL user (this script calls sudo when it needs root)
#
#  It installs packages, the Hack Nerd Font, all config files, Oh My Zsh +
#  Powerlevel10k, then sets zsh as your login shell. Existing config files are
#  backed up first. Safe to re-run (idempotent).
#
#  After it finishes: log out and pick the "i3" session at the login screen.
# =============================================================================
set -euo pipefail

NO_PACKAGES=0
P10K_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --no-packages) NO_PACKAGES=1 ;;
    --p10k-only)   P10K_ONLY=1 ;;
    -h|--help)     sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

if [[ ${EUID} -eq 0 ]]; then
  echo "Please run this as your normal user, NOT as root (it will call sudo itself)." >&2
  exit 1
fi

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  !! %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ok  %s\033[0m\n' "$*"; }

CONFIG="$HOME/.config"
BACKUP_ROOT="$HOME/.i3-mint-setup-backups"

# -----------------------------------------------------------------------------
#  Powerlevel10k compact-git prompt patch (shared by the full and --p10k-only runs)
# -----------------------------------------------------------------------------
apply_p10k_compact_git() {
  local file="${1:-$HOME/.p10k.zsh}"
  [[ -f "$file" ]] || { warn "no $file to patch"; return 0; }
  python3 - "$file" <<'P10KPATCH' || warn "p10k compact-git patch skipped (markers not found)"
import sys
p = sys.argv[1]
s = open(p).read()
start = s.find("# Show tracking branch name if it differs from local branch.")
end = s.find("    typeset -g my_git_format=$res")
if start == -1 or end == -1 or end < start:
    sys.exit(1)
compact = (
"# ---- Compact mode: hide upstream tracking, push remote, stash and file\n"
"    # counts. Show a single yellow \"\u00b1\" marker when the working tree isn't\n"
"    # clean (staged, unstaged, untracked, conflicts, stashes, ahead/behind,\n"
"    # or an in-progress action). The branch name stays green.\n"
"    if (( VCS_STATUS_COMMITS_AHEAD || VCS_STATUS_COMMITS_BEHIND )) \\\n"
"      || (( VCS_STATUS_PUSH_COMMITS_AHEAD || VCS_STATUS_PUSH_COMMITS_BEHIND )) \\\n"
"      || (( VCS_STATUS_NUM_CONFLICTED || VCS_STATUS_NUM_STAGED \\\n"
"            || VCS_STATUS_NUM_UNSTAGED || VCS_STATUS_NUM_UNTRACKED \\\n"
"            || VCS_STATUS_STASHES )) \\\n"
"      || (( VCS_STATUS_HAS_UNSTAGED == -1 )) \\\n"
"      || [[ -n $VCS_STATUS_ACTION ]]; then\n"
"      res+=\" ${modified}\u00b1\"\n"
"    fi\n"
"\n"
)
open(p, "w").write(s[:start] + compact + s[end:])
print("p10k compact-git patch applied")
P10KPATCH
}

# =============================================================================
#  --p10k-only : just (re)create ~/.p10k.zsh with the compact git segment
# =============================================================================
if [[ $P10K_ONLY -eq 1 ]]; then
  log "Powerlevel10k only"
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [[ -d "$HOME/.oh-my-zsh" ]] || { warn "Oh My Zsh not installed; run setup.sh without --p10k-only first"; exit 1; }
  [[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] || \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
  preset="$ZSH_CUSTOM/themes/powerlevel10k/config/p10k-lean.zsh"
  [[ -f "$preset" ]] && cp "$preset" "$HOME/.p10k.zsh" || warn "p10k-lean preset not found"
  apply_p10k_compact_git "$HOME/.p10k.zsh"
  ok "done — open a new terminal (or run 'exec zsh') to see the prompt"
  exit 0
fi

# =============================================================================
#  0. Sanity / backup
# =============================================================================
command -v apt-get >/dev/null 2>&1 || { warn "This script targets Debian/Ubuntu/Mint (apt)."; }
if [[ ! -f /etc/linuxmint/info ]]; then
  warn "Not detected as Linux Mint — continuing anyway."
fi

BACKUP="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
if [[ $NO_PACKAGES -eq 0 ]]; then
  log "Backing up existing config to $BACKUP"
  mkdir -p "$BACKUP"
  for f in \
    "$CONFIG/i3" "$CONFIG/i3status" "$CONFIG/picom" "$CONFIG/rofi" "$CONFIG/alacritty" \
    "$CONFIG/gtk-3.0/settings.ini" "$CONFIG/gtk-4.0/settings.ini" \
    "$HOME/.zshrc" "$HOME/.p10k.zsh" "$HOME/.gtkrc-2.0"; do
    [[ -e "$f" ]] && cp -a "$f" "$BACKUP"/ 2>/dev/null || true
  done
  ok "backup complete"
fi

# =============================================================================
#  1. Packages
# =============================================================================
if [[ $NO_PACKAGES -eq 0 ]]; then
  log "Installing packages (you will be asked for your password)"
  sudo apt-get update
  sudo apt-get install -y \
    i3-wm i3status rofi picom feh xss-lock xautolock \
    alacritty xfce4-terminal thunar firefox \
    light-locker xfce4-power-manager network-manager-gnome blueman xfce4-screenshooter \
    mint-themes papirus-icon-theme \
    x11-xserver-utils pulseaudio-utils \
    tesseract-ocr tesseract-ocr-eng maim slop xdotool xclip libnotify-bin \
    flatpak \
    zsh git curl wget unzip
  ok "packages installed"
else
  log "Skipping package installation (--no-packages)"
fi

# =============================================================================
#  2. Hack Nerd Font (user-local)
# =============================================================================
log "Installing Hack Nerd Font to ~/.local/share/fonts/HackNerdFont"
FONT_DIR="$HOME/.local/share/fonts/HackNerdFont"
mkdir -p "$FONT_DIR" "$HOME/.local/share/fonts"
TMP="$(mktemp -d)"
if curl -fsSL -o "$TMP/Hack.zip" \
     "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"; then
  unzip -oq "$TMP/Hack.zip" -d "$FONT_DIR"
  fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
  ok "Hack Nerd Font installed"
else
  warn "Font download failed — get Hack.zip from github.com/ryanoasis/nerd-fonts/releases and unzip to $FONT_DIR"
fi
rm -rf "$TMP"

# =============================================================================
#  3. Config directories
# =============================================================================
mkdir -p "$CONFIG/i3" "$CONFIG/i3status" "$CONFIG/picom" "$CONFIG/rofi" \
         "$CONFIG/alacritty" "$CONFIG/gtk-3.0" "$CONFIG/gtk-4.0"

# ---------------------------------------------------------------------------
#  3a. i3 config
# ---------------------------------------------------------------------------
log "Writing i3 config"
cat > "$CONFIG/i3/config" <<'I3CONF'
# =============================================================================
#  i3 window manager configuration
#  Linux Mint 22.x "Zena" (Xfce host, X11 session)  |  i3 4.23
#  Modifier key = Super (Windows) key  =  $mod
# =============================================================================

set $mod Mod4
set $alt Mod1

font pango:Hack Nerd Font Mono 10

# -----------------------------------------------------------------------------
#  Colors (Nord-ish)
# -----------------------------------------------------------------------------
# class                  border   background  text      indicator  child_border
client.focused           #81a2be  #4c566a     #eceff4   #88c0d0    #4c566a
client.focused_inactive  #434c5e  #3b4252     #d8dee9   #4c566a    #3b4252
client.unfocused         #434c5e  #2e3440     #d8dee9   #2e3440    #2e3440
client.urgent            #bf616a  #bf616a     #eceff4   #bf616a    #bf616a
client.placeholder       #2e3440  #2e3440     #eceff4   #2e3440    #2e3440
client.background        #2e3440

# -----------------------------------------------------------------------------
#  Programs & variables
# -----------------------------------------------------------------------------
set $term        alacritty
set $term2       xfce4-terminal
set $browser     firefox
set $filemanager thunar
set $menu        rofi -show drun
set $wallpaper   /usr/share/backgrounds/linuxmint/default_background.jpg

# -----------------------------------------------------------------------------
#  Layout: gaps (i3 4.22+), borders
# -----------------------------------------------------------------------------
gaps inner 8
gaps outer 4
smart_gaps on
smart_borders on

default_border pixel 2
default_floating_border pixel 2
hide_edge_borders smart

floating_modifier $mod

# -----------------------------------------------------------------------------
#  Autostart
# -----------------------------------------------------------------------------
exec ~/.config/i3/transparency.sh restart
exec ~/.config/i3/wallpaper.sh restore
exec xfsettingsd
exec nm-applet
exec blueman-applet
exec xfce4-power-manager
exec light-locker
exec xss-lock --transfer-sleep-lock -- light-locker-command -l
exec xautolock -time 10 -locker "light-locker-command -l"
exec xset s off
exec xset dpms 0 0 900

# -----------------------------------------------------------------------------
#  Launching programs
# -----------------------------------------------------------------------------
bindsym $mod+Return        exec $term
bindsym $mod+Shift+Return  exec $browser
bindsym $mod+Ctrl+Return   exec $term2
bindsym $mod+Shift+f       exec $filemanager
bindsym $mod+d             exec $menu
bindsym $mod+Shift+d       exec rofi -show run
bindsym $mod+Tab           exec rofi -show window

# -----------------------------------------------------------------------------
#  Window management
# -----------------------------------------------------------------------------
bindsym $mod+q      kill
bindsym $mod+w      kill
bindsym $mod+f      fullscreen toggle
bindsym $mod+space     exec $menu
bindsym $mod+Alt+space focus mode_toggle
bindsym $mod+Shift+space floating toggle
bindsym $mod+a      focus parent

# splitting & layout
bindsym $mod+b      split h
bindsym $mod+v      split v
bindsym $mod+s      layout stacking
bindsym $mod+Shift+w  layout tabbed
bindsym $mod+e      layout toggle split

# -----------------------------------------------------------------------------
#  Focus & movement
# -----------------------------------------------------------------------------
bindsym $mod+Left    focus left
bindsym $mod+Down    focus down
bindsym $mod+Up      focus up
bindsym $mod+Right   focus right
bindsym $alt+h       focus left
bindsym $alt+j       focus down
bindsym $alt+k       focus up
bindsym $alt+l       focus right

bindsym $mod+Shift+Left  move left
bindsym $mod+Shift+Down  move down
bindsym $mod+Shift+Up    move up
bindsym $mod+Shift+Right move right
bindsym $mod+Shift+h     move left
bindsym $mod+Shift+j     move down
bindsym $mod+Shift+k     move up
bindsym $mod+Shift+l     move right

# -----------------------------------------------------------------------------
#  Workspaces 1-10
# -----------------------------------------------------------------------------
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+0 workspace number 10

bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+Shift+9 move container to workspace number 9
bindsym $mod+Shift+0 move container to workspace number 10

# -----------------------------------------------------------------------------
#  Resize mode ($mod+r to enter, Esc/Enter to leave)
# -----------------------------------------------------------------------------
mode "resize" {
    bindsym Left        resize shrink width  10 px or 10 ppt
    bindsym Right       resize grow   width  10 px or 10 ppt
    bindsym Up          resize shrink height 10 px or 10 ppt
    bindsym Down        resize grow   height 10 px or 10 ppt
    bindsym h           resize shrink width  10 px or 10 ppt
    bindsym l           resize grow   width  10 px or 10 ppt
    bindsym k           resize shrink height 10 px or 10 ppt
    bindsym j           resize grow   height 10 px or 10 ppt

    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# -----------------------------------------------------------------------------
#  Lock / power / screenshots
# -----------------------------------------------------------------------------
bindsym $mod+Escape     exec light-locker-command -l
bindsym $mod+Shift+x    exec ~/.config/i3/power-menu.sh
bindsym Print               exec xfce4-screenshooter -f
bindsym $mod+Print          exec xfce4-screenshooter -r
# Omarchy-style OCR: select a region, extract the text, copy it to the clipboard
bindsym $mod+Ctrl+Print     exec ~/.config/i3/screenshot-ocr.sh region
bindsym $mod+Ctrl+Shift+Print exec ~/.config/i3/screenshot-ocr.sh full

# -----------------------------------------------------------------------------
#  Wallpaper & transparency
# -----------------------------------------------------------------------------
bindsym $mod+Ctrl+w          exec ~/.config/i3/wallpaper.sh pick
bindsym $mod+Ctrl+Shift+w    exec ~/.config/i3/wallpaper.sh random
bindsym $mod+Ctrl+t          exec ~/.config/i3/transparency.sh toggle
bindsym $mod+Ctrl+Shift+t    exec ~/.config/i3/transparency.sh global
bindsym $mod+Ctrl+Up         exec ~/.config/i3/transparency.sh up
bindsym $mod+Ctrl+Down       exec ~/.config/i3/transparency.sh down
bindsym $mod+Ctrl+r          exec ~/.config/i3/transparency.sh reset

# -----------------------------------------------------------------------------
#  Media / hardware keys
# -----------------------------------------------------------------------------
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute        exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86AudioMicMute     exec pactl set-source-mute @DEFAULT_SOURCE@ toggle
# No brightnessctl installed by default; uncomment after installing it:
# bindsym XF86MonBrightnessUp   exec brightnessctl set +5%
# bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

# -----------------------------------------------------------------------------
#  i3 reload / restart / exit
# -----------------------------------------------------------------------------
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Exit i3? You can log back in from LightDM.' -B 'Yes' 'i3-msg exit'"

# -----------------------------------------------------------------------------
#  Status bar
# -----------------------------------------------------------------------------
bar {
    status_command i3status
    position top
    tray_output primary
    font pango:Hack Nerd Font Mono 10

    colors {
        background #2e3440
        statusline #d8dee9
        separator  #4c566a

        focused_workspace  #88c0d0 #4c566a #eceff4
        active_workspace   #3b4252 #3b4252 #d8dee9
        inactive_workspace #2e3440 #2e3440 #7b8794
        urgent_workspace   #bf616a #bf616a #eceff4
    }
}
I3CONF
ok "i3 config written"

# ---------------------------------------------------------------------------
#  3b. Helper scripts
# ---------------------------------------------------------------------------
log "Writing helper scripts (transparency.sh, wallpaper.sh, power-menu.sh)"

cat > "$CONFIG/i3/transparency.sh" <<'TPL'
#!/usr/bin/env bash
# Window transparency control for i3 + picom (picom 10 on Mint 22.3).
#
#   transparency.sh toggle    toggle opacity of the FOCUSED window (80% <-> off)
#   transparency.sh up        focused window +5% opacity
#   transparency.sh down      focused window -5% opacity
#   transparency.sh reset     remove opacity from ALL windows
#   transparency.sh global    toggle transparency for ALL unfocused windows
#                             (rewrites picom.conf and restarts picom)
#   transparency.sh restart   (re)start picom with ~/.config/picom/picom.conf

set -euo pipefail

CONF="$HOME/.config/picom/picom.conf"
OPAQUE="1.0"
ACTIVE_TRANSLUCENT="0.85"
INACTIVE_TRANSLUCENT="0.80"

restart_picom() {
    pkill -x picom 2>/dev/null || true
    sleep 0.3
    setsid -f picom >/dev/null 2>&1 || true
}

case "${1:-toggle}" in
    status)
        grep -E '^(active|inactive)-opacity' "$CONF"
        ;;
    toggle)  picom-trans -c --toggle 80 ;;
    up)      picom-trans -c -o +5 ;;
    down)    picom-trans -c -o -5 ;;
    reset)   picom-trans --reset ;;
    restart) restart_picom ;;
    global)
        if grep -qE "^inactive-opacity = ${INACTIVE_TRANSLUCENT}\b" "$CONF"; then
            new_active="$OPAQUE"
            new_inactive="$OPAQUE"
        else
            new_active="$ACTIVE_TRANSLUCENT"
            new_inactive="$INACTIVE_TRANSLUCENT"
        fi
        sed -i "s/^active-opacity = .*/active-opacity = ${new_active};/" "$CONF"
        sed -i "s/^inactive-opacity = .*/inactive-opacity = ${new_inactive};/" "$CONF"
        restart_picom
        ;;
    *)
        echo "usage: $0 {toggle|up|down|reset|global|restart}" >&2
        exit 2
        ;;
esac
TPL

cat > "$CONFIG/i3/wallpaper.sh" <<'WPF'
#!/usr/bin/env bash
# Wallpaper setter / picker for i3 (feh based).
#
#   wallpaper.sh            pick a wallpaper with rofi
#   wallpaper.sh pick       same as above
#   wallpaper.sh random     apply a random wallpaper
#   wallpaper.sh restore    re-apply the last wallpaper (used at login)
#   wallpaper.sh <file>     apply a specific file
#
# The last applied wallpaper is remembered in ~/.config/i3/.wallpaper

set -euo pipefail

DEFAULT="/usr/share/backgrounds/linuxmint/default_background.jpg"
STATE="$HOME/.config/i3/.wallpaper"
DIRS=(
    "$HOME/Pictures/Wallpapers"
    "$HOME/Pictures"
    "$HOME/Downloads"
    "$HOME/Desktop"
    "$HOME/.local/share/wallpapers"
    "/usr/share/backgrounds/linuxmint-wallpapers"
    "/usr/share/backgrounds/linuxmint"
    "/usr/share/backgrounds/xfce"
)

list_wallpapers() {
    local d
    for d in "${DIRS[@]}"; do
        [[ -d "$d" ]] || continue
        find "$d" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
               -o -iname '*.webp' -o -iname '*.bmp' \) 2>/dev/null
    done | sort -u
}

apply() {
    [[ -f "$1" ]] || return 1
    feh --bg-fill "$1"
    printf '%s\n' "$1" > "$STATE"
}

case "${1:-pick}" in
    list)
        list_wallpapers
        ;;
    restore)
        if [[ -f "$STATE" && -f "$(cat "$STATE")" ]]; then
            apply "$(cat "$STATE")"
        else
            apply "$DEFAULT"
        fi
        ;;
    random)
        mapfile -t all < <(list_wallpapers)
        if [[ ${#all[@]} -gt 0 ]]; then
            apply "${all[RANDOM % ${#all[@]}]}"
        else
            apply "$DEFAULT"
        fi
        ;;
    pick)
        mapfile -t all < <(list_wallpapers)
        if [[ ${#all[@]} -eq 0 ]]; then
            rofi -e "No wallpapers found."
            exit 1
        fi
        declare -A map
        for f in "${all[@]}"; do
            map["$(basename "$(dirname "$f")")/$(basename "$f")"]="$f"
        done
        choice=$(printf '%s\n' "${!map[@]}" | sort \
            | rofi -dmenu -i -p "Wallpaper" -lines 12)
        [[ -n "${choice:-}" ]] && apply "${map[$choice]}"
        ;;
    *)
        apply "$1"
        ;;
esac
WPF

cat > "$CONFIG/i3/power-menu.sh" <<'PWR'
#!/usr/bin/env bash
# Power menu for i3, shown through rofi.
# Bound to $mod+Shift+x in ~/.config/i3/config

chosen=$(printf 'Lock\nSuspend\nLog out\nReboot\nShut down' | rofi -dmenu -i -p 'Power' -lines 5)

case "$chosen" in
    Lock)       light-locker-command -l ;;
    Suspend)    systemctl suspend ;;
    "Log out")  i3-msg exit ;;
    Reboot)     systemctl reboot ;;
    "Shut down") systemctl poweroff ;;
    *)          exit 0 ;;
esac
PWR

cat > "$CONFIG/i3/screenshot-ocr.sh" <<'OCRSH'
#!/usr/bin/env bash
# =============================================================================
#  screenshot-ocr.sh  —  Omarchy-style "extract text from a screenshot" for i3
#
#    screenshot-ocr.sh          select a region, OCR it, copy the text to the
#    screenshot-ocr.sh region   clipboard (default — same as Omarchy)
#    screenshot-ocr.sh full     OCR the entire screen
#    screenshot-ocr.sh window   OCR the currently focused window
#
#  The recognised text is placed on the PRIMARY clipboard selection and the
#  CLIPBOARD selection, and a preview is shown as a notification.
#
#  Requires: tesseract-ocr, maim (region capture) + slop (region selector),
#            xclip (clipboard), libnotify (notify-send).
#
#  Environment overrides:
#    SCREENSHOT_OCR_LANGS   tesseract language(s), default "eng"
#                           e.g. SCREENSHOT_OCR_LANGS="eng+vie"
#    SCREENSHOT_OCR_KEEP=1  also save the captured PNG (default: don't)
#    SCREENSHOT_OCR_DIR     where to save it, default ~/Pictures/Screenshots
#
#  Bound in ~/.config/i3/config to:  $mod+Ctrl+Print  (region)
#                                    $mod+Ctrl+Shift+Print (full screen)
# =============================================================================

LANGS="${SCREENSHOT_OCR_LANGS:-eng}"
SHOT_DIR="${SCREENSHOT_OCR_DIR:-$HOME/Pictures/Screenshots}"
TMP="$(mktemp --suffix=.png)" || exit 1
trap 'rm -f "$TMP"' EXIT

notify() { notify-send -a "Screenshot OCR" -i "${2:-edit-copy}" "$1" "${3:-}" 2>/dev/null || true; }

have() { command -v "$1" >/dev/null 2>&1; }

capture_region() {
    if have maim; then
        maim -s "$TMP" 2>/dev/null
    elif have scrot; then
        scrot -s -o "$TMP" 2>/dev/null
    elif have import; then
        import "$TMP" 2>/dev/null
    else
        notify "OCR not set up" "dialog-error" "Install maim (or scrot) for region capture."
        exit 1
    fi
}

capture_full() {
    if have maim; then
        maim "$TMP" 2>/dev/null
    elif have scrot; then
        scrot -o "$TMP" 2>/dev/null
    elif have import; then
        import -window root "$TMP" 2>/dev/null
    else
        notify "OCR not set up" "dialog-error" "Install maim (or scrot)."
        exit 1
    fi
}

capture_window() {
    if have maim && have xdotool; then
        local wid
        wid="$(xdotool getactivewindow 2>/dev/null)" || wid=""
        if [[ -n "$wid" ]]; then maim -i "$wid" "$TMP" 2>/dev/null && return; fi
    fi
    capture_region
}

if ! have tesseract; then
    notify "OCR engine missing" "dialog-error" "tesseract is not installed."
    exit 1
fi

case "${1:-region}" in
    full)   capture_full ;;
    window) capture_window ;;
    *)      capture_region ;;
esac

# Nothing captured (user pressed Esc / cancelled the selection).
[[ -s "$TMP" ]] || exit 0

# Optionally keep a copy of the screenshot.
if [[ "${SCREENSHOT_OCR_KEEP:-0}" == "1" ]]; then
    mkdir -p "$SHOT_DIR"
    cp "$TMP" "$SHOT_DIR/ocr-$(date +%Y-%m-%d_%H-%M-%S).png" 2>/dev/null || true
fi

# --- Run OCR (same tesseract flags Omarchy uses) ------------------------------
TEXT="$(tesseract "$TMP" stdout \
        --oem 1 --psm 6 -l "$LANGS" \
        --dpi 300 -c preserve_interword_spaces=1 2>/dev/null)" || TEXT=""

# Trim trailing whitespace only.
TEXT="${TEXT%"${TEXT##*[![:space:]]}"}"

if [[ -z "${TEXT//[[:space:]]/}" ]]; then
    notify "No text found" "dialog-information" "Nothing recognisable in the selection."
    exit 0
fi

# --- Copy to both clipboard selections ----------------------------------------
if have xclip; then
    printf '%s' "$TEXT" | xclip -selection clipboard -i
    printf '%s' "$TEXT" | xclip -selection primary  -i
elif have xsel; then
    printf '%s' "$TEXT" | xsel --clipboard --input
    printf '%s' "$TEXT" | xsel --primary   --input
else
    notify "Copied failed" "dialog-error" "Install xclip (or xsel) to copy to the clipboard."
    exit 1
fi

# --- Notify with a short preview ---------------------------------------------
PREVIEW="$(printf '%s' "$TEXT" | tr '\n' ' ' | cut -c1-160)"
notify "Text copied to clipboard (${#TEXT} chars)" "edit-copy" "$PREVIEW"
OCRSH

chmod +x "$CONFIG/i3/transparency.sh" "$CONFIG/i3/wallpaper.sh" "$CONFIG/i3/power-menu.sh" "$CONFIG/i3/screenshot-ocr.sh"
ok "helper scripts written and marked executable"

# ---------------------------------------------------------------------------
#  3c. picom
# ---------------------------------------------------------------------------
log "Writing picom config (transparency on, blur/acrylic OFF)"
cat > "$CONFIG/picom/picom.conf" <<'PICOM'
# picom 10.2 configuration  --  Linux Mint 22.x / i3
# NOTE: picom 10 does NOT support rounded corners (corner-radius needs picom 11+).

backend = "glx";
vsync = true;

# --- Shadows -----------------------------------------------------------------
shadow = true;
shadow-radius = 14;
shadow-opacity = 0.45;
shadow-offset-x = -12;
shadow-offset-y = -12;
shadow-exclude = [
    "class_g = 'i3-frame'",
    "window_type = 'dock'",
    "window_type = 'desktop'",
    "class_g ?= 'nm-applet'"
];

# --- Fading ------------------------------------------------------------------
fading = true;
fade-in-step = 0.04;
fade-out-step = 0.04;
fade-delta = 8;

# --- Transparency (ALL windows translucent by default) -----------------------
# Toggle the whole thing off/on at runtime with Super+Ctrl+Shift+T
inactive-opacity = 0.80;
active-opacity = 0.85;
frame-opacity = 1.0;
inactive-opacity-override = false;
detect-client-opacity = true;

# Per-app rules would take priority over the global values above, so this is
# left empty on purpose to keep transparency uniform across every window.
# opacity-rule = [
#     "92:class_g = 'Alacritty' && focused",
#     "82:class_g = 'Alacritty' && !focused"
# ];

# --- Background blur ("acrylic" frosted-glass) -- DISABLED -------------------
# Pure transparency only: no blurred background behind translucent windows.
blur-background = false;
# Kept for reference; ignored while blur-background = false.
# blur-method = "dual_kawase";
# blur-strength = 5;
# blur-background-exclude = [
#     "window_type = 'dock'",
#     "window_type = 'desktop'",
#     "class_g = 'feh'"
# ];

# --- Misc --------------------------------------------------------------------
glx-no-stencil = true;
mark-wmwin-focused = true;
mark-ovredir-focused = true;
PICOM
ok "picom config written"

# ---------------------------------------------------------------------------
#  3d. i3status (auto-detect interfaces + Nerd Font icons)
# ---------------------------------------------------------------------------
log "Writing i3status config (auto-detecting network interfaces)"

detect_wifi() {
  local i n
  for i in /sys/class/net/*; do
    n="${i##*/}"
    [[ -e "$i/wireless" ]] && { printf '%s' "$n"; return; }
  done
}
detect_eth() {
  local i n
  for i in /sys/class/net/*; do
    n="${i##*/}"
    [[ "$n" == "lo" ]] && continue
    [[ -e "$i/wireless" ]] && continue
    case "$n" in
      wl*|ww*|virbr*|docker*|veth*|br-*|tun*|tap*|wg*|vmnet*|zt*) continue ;;
    esac
    printf '%s' "$n"; return
  done
}
WIFI_IF="$(detect_wifi || true)"
ETH_IF="$(detect_eth || true)"

G_WIFI="$(printf '\uf1eb')"
G_ETH="$(printf '\uf233')"
G_CPU="$(printf '\uf2db')"
G_MEM="$(printf '\uf538')"
G_DISK="$(printf '\uf0a0')"
G_VOL="$(printf '\uf028')"
G_CLOCK="$(printf '\uf017')"

I3S="$CONFIG/i3status/config"
{
cat <<'I3SHDR'
# i3status configuration -- Linux Mint 22.x / i3
# Nerd Font icons (Hack Nerd Font Mono). Interfaces auto-detected at install.

general {
        colors = true
        interval = 5
        color_good     = "#a3be8c"
        color_degraded = "#ebcb8b"
        color_bad      = "#bf616a"
}
I3SHDR

[[ -n "$WIFI_IF" ]] && printf 'order += "wireless %s"\n' "$WIFI_IF"
[[ -n "$ETH_IF"  ]] && printf 'order += "ethernet %s"\n' "$ETH_IF"
cat <<'I3SORD'
order += "cpu_usage"
order += "memory"
order += "disk /"
order += "volume master"
order += "tztime local"
I3SORD
} > "$I3S"

if [[ -n "$WIFI_IF" ]]; then
cat >> "$I3S" <<EOF

wireless $WIFI_IF {
        format_up   = "$G_WIFI %essid"
        format_down = ""
}
EOF
fi

if [[ -n "$ETH_IF" ]]; then
cat >> "$I3S" <<EOF

ethernet $ETH_IF {
        format_up   = "$G_ETH %ip"
        format_down = ""
}
EOF
fi

cat >> "$I3S" <<EOF

cpu_usage {
        format = "$G_CPU %usage"
}

memory {
        format = "$G_MEM %used"
}

disk "/" {
        format = "$G_DISK %avail"
}

volume master {
        format       = "$G_VOL %volume"
        format_muted = "$G_VOL muted"
        device       = "default"
        mixer        = "Master"
        mixer_idx    = 0
}

tztime local {
        format = "$G_CLOCK %a %d %b  %H:%M"
}
EOF
ok "i3status config written (wifi: ${WIFI_IF:-none}, eth: ${ETH_IF:-none})"

# ---------------------------------------------------------------------------
#  3e. rofi
# ---------------------------------------------------------------------------
log "Writing rofi config"
cat > "$CONFIG/rofi/config.rasi" <<'RASI'
/* rofi configuration -- Linux Mint 22.x / i3
 * Keep these options here (not on the i3 `exec` line) so the command
 * stays comma-free; i3's parser splits on commas in exec commands.
 */
configuration {
    show-icons: true;
    modi: "drun,run,window";
    display-drun: "Apps:";
    display-run: "Run:";
    display-window: "Windows:";
}
RASI
ok "rofi config written"

# ---------------------------------------------------------------------------
#  3f. alacritty
# ---------------------------------------------------------------------------
log "Writing alacritty config"
cat > "$CONFIG/alacritty/alacritty.toml" <<'ALAC'
# Alacritty configuration -- Linux Mint 22.x / i3
# Font: Hack Nerd Font Mono (installed in ~/.local/share/fonts/HackNerdFont)

[font]
size = 11.0

[font.normal]
family = "Hack Nerd Font Mono"
style = "Regular"

[font.bold]
family = "Hack Nerd Font Mono"
style = "Bold"

[font.italic]
family = "Hack Nerd Font Mono"
style = "Italic"

[font.bold_italic]
family = "Hack Nerd Font Mono"
style = "Bold Italic"
ALAC
ok "alacritty config written"

# ---------------------------------------------------------------------------
#  3g. GTK (dark theme for apps, so it applies even without xfsettingsd)
# ---------------------------------------------------------------------------
log "Writing GTK theme config (Mint-Y-Dark + Papirus-Dark)"
for GTKVER in 3.0 4.0; do
  mkdir -p "$CONFIG/gtk-$GTKVER"
  cat > "$CONFIG/gtk-$GTKVER/settings.ini" <<'GTKSET'
[Settings]
gtk-theme-name=Mint-Y-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 10
gtk-application-prefer-dark-theme=1
GTKSET
done
{
  [[ -f "$HOME/.gtkrc-xfce" ]] && echo 'include ".gtkrc-xfce"'
  echo 'gtk-theme-name="Mint-Y-Dark"'
  echo 'gtk-icon-theme-name="Papirus-Dark"'
} > "$HOME/.gtkrc-2.0"

# Also set it in xfconf so the Xfce session stays consistent
if command -v xfconf-query >/dev/null 2>&1; then
  xfconf-query -c xsettings -p /Net/ThemeName      -s "Mint-Y-Dark"   2>/dev/null || true
  xfconf-query -c xsettings -p /Net/IconThemeName  -s "Papirus-Dark"  2>/dev/null || true
fi
ok "GTK theme config written"

# ---------------------------------------------------------------------------
#  3h. Remove Xfce Super-key shortcuts (they hijack i3's keybinds)
# ---------------------------------------------------------------------------
log "Removing Xfce Super-key shortcuts (so i3 owns the Super key)"
SUPER_PROPS=("Super_L" "<Super>r" "<Super>p" "<Super>e" "<Alt><Super>s")
if command -v xfconf-query >/dev/null 2>&1; then
  for p in "${SUPER_PROPS[@]}"; do
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$p" -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$p/startup-notify" -r 2>/dev/null || true
  done
fi
# File-level fallback / belt-and-braces
XML="$CONFIG/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
if [[ -f "$XML" ]]; then
  python3 - "$XML" <<'XFCEPATCH' || true
import re, sys
p = sys.argv[1]
try:
    s = open(p).read()
except OSError:
    sys.exit(0)
names = ["Super_L", "&lt;Super&gt;r", "&lt;Super&gt;p", "&lt;Super&gt;e", "&lt;Alt&gt;&lt;Super&gt;s"]
for n in names:
    pat = re.compile(
        r'<property name="' + re.escape(n) + r'" type="string" value="[^"]*"\s*/>'
        r'|<property name="' + re.escape(n) + r'" type="string" value="[^"]*">.*?</property>',
        re.S)
    s = pat.sub('<property name="' + n + '" type="empty"/>', s)
open(p, "w").write(s)
XFCEPATCH
fi
ok "Xfce Super shortcuts cleared"

# =============================================================================
#  4. Desktop apps (Flatpak: LocalSend + ONLYOFFICE Desktop Editors)
# =============================================================================
if [[ $NO_PACKAGES -eq 0 ]]; then
  log "Installing Flatpak apps (LocalSend, ONLYOFFICE Desktop Editors)"
  if command -v flatpak >/dev/null 2>&1; then
    flatpak remote-add --user --if-not-exists flathub \
      https://flathub.org/repo/flathub.flatpakrepo || warn "could not add flathub user remote"
    flatpak install --user -y flathub \
      org.localsend.localsend_app \
      org.onlyoffice.desktopeditors \
      || warn "Flatpak app install failed — retry with: flatpak install --user flathub org.localsend.localsend_app org.onlyoffice.desktopeditors"
    ok "Flatpak apps installed (launch from rofi: Super+Space)"
  else
    warn "flatpak not found — skipping LocalSend + ONLYOFFICE"
  fi
else
  log "Skipping Flatpak apps (--no-packages)"
fi

# =============================================================================
#  5. Shell: Oh My Zsh + Powerlevel10k + plugins
# =============================================================================
log "Installing Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    || warn "Oh My Zsh installer failed — you can re-run setup.sh"
else
  ok "Oh My Zsh already present"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
log "Installing Powerlevel10k + zsh plugins"
[[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] || \
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" || warn "p10k clone failed"
[[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || warn "autosuggestions clone failed"
[[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || warn "syntax-highlighting clone failed"

log "Writing ~/.zshrc"
cat > "$HOME/.zshrc" <<'ZSHRC'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme: Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git z sudo extract zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# --- keep opencode on PATH (harmless if the folder doesn't exist) ---
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHRC
ok "~/.zshrc written"

log "Writing ~/.p10k.zsh (lean + compact git)"
P10K_PRESET="$ZSH_CUSTOM/themes/powerlevel10k/config/p10k-lean.zsh"
if [[ -f "$P10K_PRESET" ]]; then
  cp "$P10K_PRESET" "$HOME/.p10k.zsh"
  apply_p10k_compact_git "$HOME/.p10k.zsh"
else
  warn "p10k-lean preset not found; skipping ~/.p10k.zsh"
fi

# =============================================================================
#  6. Default shell = zsh
# =============================================================================
log "Setting zsh as your login shell"
ZSH_BIN="$(command -v zsh || true)"
if [[ -n "$ZSH_BIN" ]]; then
  grep -qx "$ZSH_BIN" /etc/shells 2>/dev/null || echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  if [[ "${SHELL:-}" != "$ZSH_BIN" ]]; then
    chsh -s "$ZSH_BIN" || warn "chsh failed; run manually:  chsh -s $ZSH_BIN"
  else
    ok "zsh is already your login shell"
  fi
else
  warn "zsh not found — install it and run: chsh -s /usr/bin/zsh"
fi

# =============================================================================
#  Done
# =============================================================================
log "All done!"
cat <<'DONE'

  Next steps:
    1. LOG OUT, then at the login screen pick the "i3" session.
    2. Open a terminal:  Super+Return   (Alacritty)
    3. App launcher:     Super+Space    (rofi)

  See ~/i3-mint-setup/KEYBINDINGS.md for every shortcut.
  Re-run this script any time (it backs up first). To only restore the
  Powerlevel10k prompt after running `p10k configure`:
        bash setup.sh --p10k-only

DONE
