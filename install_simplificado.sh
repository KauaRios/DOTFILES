#!/bin/bash
# DOTFILES INSTALLER — KauaRios/DOTFILES
set -euo pipefail

# ── Cores ─────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' N='\033[0m' BOLD='\033[1m'
info() { echo -e "${B}[•]${N} $*"; }
ok()   { echo -e "${G}[✓]${N} $*"; }
warn() { echo -e "${Y}[!]${N} $*"; }
die()  { echo -e "${R}[✗]${N} $*" >&2; exit 1; }

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$REPO/DOTFILES/install.sh" ]] && REPO="$REPO/DOTFILES"

EXCLUDE=(install.sh requirements.txt README.md .gitignore LICENSE .git starship.toml)

# ── Pacotes ───────────────────────────────────────────
PKGS=(
    hyprland hyprlock hyprpaper
    waybar wofi mako wlogout
    kitty alacritty fish starship fastfetch
    pipewire wireplumber pavucontrol brightnessctl
    playerctl btop rofi hyprshot grim slurp wl-clipboard
    ttf-jetbrains-mono-nerd cantarell-fonts ttf-fira-sans
    otf-font-awesome ttf-hack-nerd ttf-sarasa-gothic
    imagemagick gnome-themes-extra nwg-look qt5ct qt6ct kvantum xsettingsd
    fzf
)

# ── AUR helper ────────────────────────────────────────
get_aur() {
    if command -v yay &>/dev/null; then echo "yay"
    elif command -v paru &>/dev/null; then echo "paru"
    else
        warn "Instalando paru..."
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/paru.git /tmp/_paru
        (cd /tmp/_paru && makepkg -si --noconfirm) && rm -rf /tmp/_paru
        echo "paru"
    fi
}

install_pkgs() {
    local aur
    aur="$(get_aur)"
    info "Instalando pacotes com $aur..."
    "$aur" -S --needed --noconfirm "${PKGS[@]}" || warn "Alguns pacotes falharam — verifique manualmente."
}

# ── Backup + Symlinks ─────────────────────────────────
sync_dotfiles() {
    local bak="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$HOME/.config"

    for item in "$REPO"/*; do
        local name; name="$(basename "$item")"
        # pula exclusões
        for ex in "${EXCLUDE[@]}"; do [[ "$name" == "$ex" ]] && continue 2; done

        local dst="$HOME/.config/$name"
        if [[ -L "$dst" ]]; then
            rm "$dst"
        elif [[ -e "$dst" ]]; then
            mkdir -p "$bak"
            mv "$dst" "$bak/"
            info "Backup: ~/.config/$name"
        fi
        ln -sfn "$item" "$dst"
        ok "Link: $name"
    done

    # starship.toml vai direto em ~/.config/
    [[ -f "$REPO/starship.toml" ]] && ln -sfn "$REPO/starship.toml" "$HOME/.config/starship.toml" && ok "Link: starship.toml"
}

# ── Pós-instalação ────────────────────────────────────
post_install() {
    # Expande $HOME no hyprpaper.conf
    local hp="$HOME/.config/hypr/hyprpaper.conf"
    if [[ -L "$hp" ]]; then cp "$(readlink "$hp")" "$hp"; fi
    [[ -f "$hp" ]] && sed -i "s|HOMEPATH|$HOME|g" "$hp" && ok "hyprpaper.conf: paths expandidos"

    # Guard cachyos-fish-config no config.fish
    local fc="$HOME/.config/fish/config.fish"
    if [[ -L "$fc" ]]; then cp "$(readlink "$fc")" "$fc"; fi
    if [[ -f "$fc" ]] && grep -q "source /usr/share/cachyos-fish-config" "$fc"; then
        python3 - "$fc" <<'PY'
import sys; p=sys.argv[1]; t=open(p).read()
t=t.replace(
    "source /usr/share/cachyos-fish-config/cachyos-config.fish",
    "if test -f /usr/share/cachyos-fish-config/cachyos-config.fish\n    source /usr/share/cachyos-fish-config/cachyos-config.fish\nend"
)
if "fish_greeting" not in t:
    t+="\nfunction fish_greeting\n    if not test -f /usr/share/cachyos-fish-config/cachyos-config.fish\n        command -q fastfetch && fastfetch\n    end\nend\n"
open(p,"w").write(t)
PY
        ok "config.fish: guard CachyOS adicionado"
    fi

    # fisher + plugins
    if command -v fish &>/dev/null; then
        fish -c "
            functions -q fisher || begin
                curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
                fisher install jorgebucaran/fisher
            end
            fisher install PatrickF1/fzf.fish franciscolourenco/done jorgebucaran/autopair.fish 2>/dev/null
        " 2>/dev/null && ok "fisher + plugins instalados"
    fi

    # Permissões waybar scripts
    find "$HOME/.config/waybar" -name "*.sh" -o -name "*.py" 2>/dev/null | xargs chmod +x 2>/dev/null || true

    # fish como shell padrão
    local fp; fp="$(command -v fish)"
    [[ "$SHELL" != "$fp" ]] && {
        grep -qF "$fp" /etc/shells || echo "$fp" | sudo tee -a /etc/shells
        sudo usermod -s "$fp" "$(logname 2>/dev/null || id -un)" && ok "fish como shell padrão"
    }

    # Recarrega Hyprland se rodando
    command -v hyprctl &>/dev/null && hyprctl version &>/dev/null && hyprctl reload 2>/dev/null || true
}

# ── Main ──────────────────────────────────────────────
echo -e "\n${BOLD}══ DOTFILES — KauaRios ══${N}"
echo -e "  Repo: ${BOLD}$REPO${N} → ${BOLD}~/.config/${N}\n"
read -rp "$(echo -e "${Y}Iniciar instalação? [s/N]${N} ")" r
[[ "$r" =~ ^[Ss]$ ]] || { info "Cancelado."; exit 0; }

install_pkgs
sync_dotfiles
post_install

echo -e "\n${G}${BOLD}══ Concluído! ══${N}"
warn "Crie ~/.config/waybar/modules/mailsecrets.py com suas credenciais IMAP."
info "Reinicie a sessão para aplicar tudo."
