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

# -- Enable multilib
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

# ── Install packages
install_packages() {
    section "Installing packages"

    local pkg_file="$DOTFILES/packages.txt"
    if [ ! -f "$pkg_file" ]; then
        warn "packages.txt not found, skipping"
        return
    fi

    # Install yay and enable multilib
    grep -qE '^(aur|optional) ' "$pkg_file" && install_yay
    grep -qE '^pacman lib32' "$pkg_file" && enable_multilib

    local aur_helper=""
    for h in yay paru; do
        command -v $h &>/dev/null && aur_helper=$h && break
    done

    local total=0 installed=0 skipped=0 failed=0

    # Helper install pacman
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

    # Helper install AUR
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
                    # Coba pacman dulu, fallback AUR
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

# ── Symlink configs
link_configs() {
    section "Linking configs"

    if [ ! -d "$CONFIG" ]; then
        warn "No .config dir found at $CONFIG"
        return
    fi

    for src in "$CONFIG"/*/; do
        local name dst
        name=$(basename "$src")
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

    local assets_dir="$RICE/assets"
    if [ ! -d "$assets_dir" ]; then
        skip "No assets dir found"
        return
    fi

    for file in "$assets_dir"/*; do
        local name
        name=$(basename "$file")
        ln -sfn "$file" "$HOME/$name"
        success "${BOLD}$name${RESET} ${DIM}→ ~/$name${RESET}"
    done
}

# ── Main
case "${1:-all}" in
    packages) install_packages ;;
    links)    link_configs; link_assets ;;
    all)      install_packages; link_configs; link_assets ;;
    yay)      install_yay ;;
    *)
        echo -e "Usage: ${BOLD}$0${RESET} [all|packages|links|yay]"
        ;;
esac

echo ""
success "${BOLD}Installation complete!${RESET}"
