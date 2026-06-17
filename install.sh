#!/bin/bash

# ── Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Helpers
info()    { echo -e "${BLUE}${BOLD}[*]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[✓]${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[✗]${RESET} $*"; }
skip()    { echo -e "${DIM}[~] $*${RESET}"; }
section() { echo -e "\n${CYAN}${BOLD}══ $* ══${RESET}"; }

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
RICE="$DOTFILES/my-rice"
CONFIG="$RICE/.config"

info "Dotfiles : ${BOLD}$DOTFILES${RESET}"
info "Home     : ${BOLD}$HOME${RESET}"

# ── Install yay
install_yay() {
    if command -v yay &>/dev/null; then
        skip "yay already installed"
        return
    fi

    section "Installing yay"
    info "Building yay from AUR..."

    sudo pacman -S --noconfirm --needed git base-devel

    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"

    if command -v yay &>/dev/null; then
        success "yay installed"
    else
        error "yay installation failed"
        exit 1
    fi
}

# ── Enable multilib
enable_multilib() {
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        skip "multilib already enabled"
        return
    fi

    section "Enabling multilib"
    sudo sed -i '/^#\[multilib\]/{n;s/^#Include/Include/}' /etc/pacman.conf
    sudo sed -i 's/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf
    sudo pacman -Sy
    success "multilib enabled"
}

# ── Setup pentest dirs
setup_pentest() {
    section "Setting up pentest dirs"
    mkdir -p "$HOME/.local/share/pentest-sessions"
    success "pentest-sessions dir created"
}

# ── Install packages
install_packages() {
    section "Installing packages"

    local pkg_file="$DOTFILES/packages.txt"
    if [ ! -f "$pkg_file" ]; then
        warn "packages.txt not found, skipping"
        return
    fi

    grep -qE '^(aur|optional) ' "$pkg_file" && install_yay
    grep -qE '^pacman lib32' "$pkg_file" && enable_multilib

    local aur_helper=""
    for h in yay paru; do
        command -v $h &>/dev/null && aur_helper=$h && break
    done

    local total=0 installed=0 skipped=0 failed=0

    _install_pacman() {
        local pkg="$1"
        if pacman -Qi "$pkg" &>/dev/null; then
            skip "$pkg (already installed)"
            (( skipped++ ))
        else
            info "Installing ${BOLD}$pkg${RESET}..."
            if sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
                success "$pkg"
                (( installed++ ))
            else
                error "$pkg (failed)"
                (( failed++ ))
            fi
        fi
    }

    _install_aur() {
        local pkg="$1"
        if [ -z "$aur_helper" ]; then
            error "$pkg (no AUR helper found)"
            (( failed++ ))
            return
        fi
        if pacman -Qi "$pkg" &>/dev/null; then
            skip "$pkg (already installed)"
            (( skipped++ ))
        else
            info "Installing ${BOLD}$pkg${RESET} ${DIM}(AUR)${RESET}..."
            if $aur_helper -S --noconfirm --needed "$pkg" 2>/dev/null; then
                success "$pkg"
                (( installed++ ))
            else
                error "$pkg (failed)"
                (( failed++ ))
            fi
        fi
    }

    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        (( total++ ))

        local type pkg
        type=$(echo "$line" | awk '{print $1}')
        pkg=$(echo "$line" | awk '{print $2}')

        case "$type" in
            pacman)
                _install_pacman "$pkg"
                ;;
            aur)
                if [[ "$pkg" == "yay" || "$pkg" == "paru" ]]; then
                    skip "$pkg (handled separately)"
                    (( skipped++ ))
                    continue
                fi
                _install_aur "$pkg"
                ;;
            optional)
                echo -ne "  ${YELLOW}${BOLD}[?]${RESET} Install optional ${BOLD}$pkg${RESET}? (y/N) "
                read -r ans
                if [[ "$ans" =~ ^[Yy]$ ]]; then
                    if pacman -Qi "$pkg" &>/dev/null; then
                        skip "$pkg (already installed)"
                        (( skipped++ ))
                    elif sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
                        success "$pkg"
                        (( installed++ ))
                    elif [ -n "$aur_helper" ] && $aur_helper -S --noconfirm --needed "$pkg" 2>/dev/null; then
                        success "$pkg (from AUR)"
                        (( installed++ ))
                    else
                        error "$pkg (failed)"
                        (( failed++ ))
                    fi
                else
                    skip "$pkg (skipped)"
                    (( skipped++ ))
                fi
                ;;
            *)
                warn "Unknown type '${BOLD}$type${RESET}' for $pkg, skipping"
                ;;
        esac
    done < "$pkg_file"

    echo ""
    echo -e "  ${GREEN}installed: $installed${RESET}  ${DIM}skipped: $skipped${RESET}  ${RED}failed: $failed${RESET}  ${DIM}total: $total${RESET}"
}

# ── Init home directories
init_dirs() {
    section "Initializing directories"

    local dirs=(
        "$HOME/Pictures/Wallpapers"
        "$HOME/Pictures/Screenshots"
        "$HOME/Documents"
        "$HOME/Downloads"
    )

    for d in "${dirs[@]}"; do
        if [ -d "$d" ]; then
            skip "$d (already exists)"
        else
            mkdir -p "$d"
            success "Created ${BOLD}$d${RESET}"
        fi
    done
}

# ── Copy wallpapers
move_wallpapers() {
    section "Copying wallpapers"

    local wp_src="$CONFIG/Wallpapers"
    if [ ! -d "$wp_src" ]; then
        warn "No Wallpapers dir found at $wp_src, skipping"
        return
    fi

    local count=0
    for f in "$wp_src"/*; do
        [ -f "$f" ] || continue
        local name
        name=$(basename "$f")
        local dst="$HOME/Pictures/Wallpapers/$name"
        if [ -e "$dst" ]; then
            skip "$name (already exists)"
        else
            cp "$f" "$dst"
            success "${BOLD}$name${RESET} ${DIM}→ ~/Pictures/Wallpapers/${RESET}"
            (( count++ ))
        fi
    done

    [ "$count" -eq 0 ] && skip "No new wallpapers to copy" || success "Copied $count wallpaper(s)"
}

# ── Setup fastfetch
setup_fastfetch() {
    section "Setting up fastfetch"

    local template="$CONFIG/fastfetch/config.jsonc.template"
    local out_dir="$HOME/.config/fastfetch"
    local out="$out_dir/config.jsonc"

    if [ ! -f "$template" ]; then
        warn "fastfetch template not found at $template, skipping"
        return
    fi

    mkdir -p "$out_dir"
    sed "s|HOMEPATH|$HOME|g" "$template" > "$out"
    success "fastfetch config → $out"
}

# ── Setup SDDM
setup_sddm() {
    section "Setting up SDDM"

    local theme_name="elaina-sddm"
    local sddm_src="$RICE/sddm/theme"
    local sddm_dst="/usr/share/sddm/themes/$theme_name"

    if [ ! -d "$sddm_src" ]; then
        warn "No SDDM theme found at $sddm_src, skipping"
        return
    fi

    # Hapus dulu kalau udah ada biar ga nested
    if [ -d "$sddm_dst" ]; then
        sudo rm -rf "$sddm_dst"
    fi

    sudo cp -r "$sddm_src" "$sddm_dst"
    success "SDDM theme copied → $sddm_dst"

    # Generate config
    sudo mkdir -p /etc/sddm.conf.d/
    printf '[Theme]\nCurrent=%s\n' "$theme_name" | sudo tee /etc/sddm.conf.d/elaina-sddm.conf > /dev/null
    success "SDDM config → /etc/sddm.conf.d/elaina-sddm.conf"

    # Enable service
    sudo systemctl enable sddm
    success "SDDM service enabled"
}

# ── Symlink configs
link_configs() {
    section "Linking configs"

    if [ ! -d "$CONFIG" ]; then
        warn "No .config dir found at $CONFIG"
        return
    fi

    local skip_list=("Wallpapers" "fastfetch" "assets" "fish-sandbox")

    for src in "$CONFIG"/*/; do
        local name dst
        name=$(basename "$src")

        local should_skip=false
        for s in "${skip_list[@]}"; do
            [ "$name" = "$s" ] && should_skip=true && break
        done

        if $should_skip; then
            skip "$name (handled separately)"
            continue
        fi

        dst="$HOME/.config/$name"

        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            warn "Backing up ${BOLD}$name${RESET} → ${name}.bak"
            mv "$dst" "${dst}.bak"
        fi

        ln -sfn "$src" "$dst"
        success "${BOLD}$name${RESET} ${DIM}→ $dst${RESET}"
    done
}

# ── Link assets
link_assets() {
    section "Linking assets"

    local assets_src="$CONFIG/assets"
    if [ ! -d "$assets_src" ]; then
        warn "No assets dir found at $assets_src, skipping"
        return
    fi

    local dst="$HOME/.config/assets"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "Backing up assets → assets.bak"
        mv "$dst" "${dst}.bak"
    fi

    ln -sfn "$assets_src" "$dst"
    success "assets ${DIM}→ ~/.config/assets${RESET}"
}

# ── Link fish-sandbox config
link_fish_sandbox() {
    section "Linking fish-sandbox"

    local dst_dir="$HOME/.config/fish-sandbox/fish"
    mkdir -p "$dst_dir/conf.d"

    # Copy config.fish (bukan symlink, hindari loop)
    local src="$CONFIG/fish-sandbox/fish/config.fish"
    local dst="$dst_dir/config.fish"
    cp "$src" "$dst"
    success "fish-sandbox config.fish ${DIM}→ $dst${RESET}"

    # hardlink notify_broker.fish ke conf.d sandbox
    ln -f "$CONFIG/fish/conf.d/notify_broker.fish" "$dst_dir/conf.d/notify_broker.fish"
    success "notify_broker.fish ${DIM}→ fish-sandbox/conf.d${RESET}"
}

# ── Link root-level rice assets
link_rice_assets() {
    local assets_dir="$RICE/assets"
    if [ ! -d "$assets_dir" ]; then
        return
    fi

    section "Linking rice assets"
    for file in "$assets_dir"/*; do
        [ -f "$file" ] || continue
        local name
        name=$(basename "$file")
        ln -sfn "$file" "$HOME/$name"
        success "${BOLD}$name${RESET} ${DIM}→ ~/$name${RESET}"
    done
}

# ── Link hypr → hypr-custom
link_hypr() {
    section "Linking hypr"

    local src="$HOME/.config/hypr-custom"
    local dst="$HOME/.config/hypr"

    if [ ! -d "$src" ]; then
        warn "hypr-custom not found, skipping"
        return
    fi

    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "Backing up hypr → hypr.bak"
        mv "$dst" "${dst}.bak"
    fi

    rm -rf "$dst"
    ln -sfn "$src" "$dst"
    success "hypr ${DIM}→ ~/.config/hypr-custom${RESET}"
}

# ── Setup sandbox container image
setup_sandbox_image() {
    section "Setting up sandbox image"

    if ! command -v podman &>/dev/null; then
        warn "podman not found, skipping sandbox image build"
        return
    fi

    local containerfile="$DOTFILES/containers/Containerfile"
    if [ ! -f "$containerfile" ]; then
        warn "Containerfile not found at $containerfile, skipping"
        return
    fi

    info "Building kali-fish image (this may take a while)..."
    podman build -t kali-fish "$DOTFILES/containers/"
    success "kali-fish image built"
}

# ── Main
case "${1:-all}" in
    packages)  install_packages ;;
    links) link_configs; link_hypr; link_assets; link_rice_assets; link_fish_sandbox ;;
    dirs)      init_dirs; move_wallpapers ;;
    fastfetch) setup_fastfetch ;;
    sddm)      setup_sddm ;;
    all)
        install_packages
        init_dirs
        move_wallpapers
        setup_fastfetch
        setup_sddm
        setup_pentest
        setup_sandbox_image
        link_configs
        link_assets
        link_hypr
        link_rice_assets
        link_fish_sandbox
        ;;
    yay) install_yay ;;
    *)
        echo -e "Usage: ${BOLD}$0${RESET} [all|packages|links|dirs|fastfetch|sddm|yay]"
        ;;
esac

echo ""
success "${BOLD}Installation complete!${RESET}"
