#!/bin/bash
# ============================================================
#  DOTFILES INSTALLER — KauaRios/DOTFILES
#  Suporte: Arch Linux e CachyOS (apenas pacman, sem AUR helper)
# ============================================================

set -euo pipefail

# ── Cores ────────────────────────────────────────────────────
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ──────────────────────────────────────────────────
info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERRO]${NC}  $*" >&2; exit 1; }
ask()   { echo -e "${BOLD}$*${NC}"; }

safe_read() {
    local var_name="$1"
    local default="${2:-}"
    if ! IFS= read -r "$var_name" 2>/dev/null; then
        printf -v "$var_name" '%s' "$default"
    fi
}

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detecta clone aninhado (DOTFILES/DOTFILES) e corrige o path
if [[ -d "$REPO_DIR/DOTFILES" ]] && [[ -f "$REPO_DIR/DOTFILES/install.sh" ]]; then
    REPO_DIR="$REPO_DIR/DOTFILES"
fi

# Arquivos do repo que NÃO vão para ~/.config
EXCLUDE_LIST=("install.sh" "requirements.txt" "README.md" ".gitignore" "LICENSE" ".git" "starship.toml")

# ── Verificações iniciais ────────────────────────────────────
check_requirements() {
    info "Verificando dependências básicas..."

    # Garante que está no Arch ou CachyOS
    if [[ ! -f /etc/os-release ]]; then
        error "/etc/os-release não encontrado. Sistema não suportado."
    fi

    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-}"

    if ! echo "$DISTRO_ID $DISTRO_LIKE" | grep -qiE "arch|cachyos|endeavour|manjaro|garuda"; then
        error "Este installer é apenas para Arch Linux e CachyOS. Distro detectada: $DISTRO_ID"
    fi

    IS_CACHYOS=false
    if echo "$DISTRO_ID" | grep -qi "cachyos"; then
        IS_CACHYOS=true
    fi

    for cmd in git curl sudo pacman; do
        if ! command -v "$cmd" &>/dev/null; then
            error "Comando '$cmd' não encontrado. Instale-o antes de continuar."
        fi
    done

    if [[ "$XDG_SESSION_TYPE" != "wayland" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        warn "Sessão Wayland não detectada. Este setup é otimizado para Hyprland/Wayland."
        ask "Continuar mesmo assim? [s/N]"
        local resp
        safe_read resp "n"
        [[ "$resp" =~ ^[Ss]$ ]] || { info "Instalação cancelada."; exit 0; }
    fi

    info "Distro detectada: ${BOLD}$DISTRO_ID${NC}"
    $IS_CACHYOS && info "Modo CachyOS ativado."
    ok "Verificações OK."
}

# ── Instalação de pacotes via pacman ─────────────────────────
install_packages() {
    info "Instalando pacotes via pacman (sem AUR helper)..."

    # Todos esses pacotes estão nos repos oficiais do Arch e CachyOS.
    # ttf-sarasa-gothic é o único que só existe no AUR — instalado via GitHub abaixo.
    local PKGS=(
        # Hyprland ecosystem
        hyprland hyprlock hyprpaper wlogout
        # Bar, launcher, notificações
        waybar wofi mako
        # Terminais e shell
        kitty alacritty fish starship fastfetch
        # Áudio e brilho
        pipewire wireplumber pavucontrol brightnessctl
        # Utilitários
        playerctl btop rofi grim slurp wl-clipboard
        # Fontes (todas no pacman, sem AUR)
        ttf-jetbrains-mono-nerd   # kitty.conf
        cantarell-fonts            # hyprlock.conf
        ttf-fira-sans              # waybar/style.css
        otf-font-awesome           # waybar/style.css
        ttf-hack-nerd              # wofi/style.css
        # GTK / Qt / Temas
        imagemagick gnome-themes-extra nwg-look qt5ct qt6ct kvantum xsettingsd
    )

    sudo pacman -S --needed --noconfirm "${PKGS[@]}" \
        || warn "Alguns pacotes falharam — verifique manualmente."

    # Sarasa Gothic: só existe no AUR, então baixamos direto do GitHub
    _install_sarasa_gothic

    ok "Pacotes instalados."
}

# ── Instala Sarasa Gothic direto do GitHub (evita AUR) ──────
_install_sarasa_gothic() {
    if fc-list 2>/dev/null | grep -qi "sarasa"; then
        info "Sarasa Gothic já instalada, pulando."
        return
    fi

    info "Buscando versão mais recente da Sarasa Gothic..."
    local ver
    ver="$(curl -s "https://api.github.com/repos/be5invis/Sarasa-Gothic/releases/latest" \
        | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"v\([^"]*\)".*/\1/')" || true

    if [[ -z "$ver" ]]; then
        warn "Não foi possível obter versão da Sarasa Gothic."
        warn "Instale manualmente: https://github.com/be5invis/Sarasa-Gothic/releases"
        return
    fi

    # Precisa de p7zip para extrair
    if ! command -v 7z &>/dev/null && ! command -v 7za &>/dev/null; then
        info "Instalando p7zip para extrair a fonte..."
        sudo pacman -S --needed --noconfirm p7zip || true
    fi

    info "Instalando Sarasa Gothic ${ver}..."
    local url="https://github.com/be5invis/Sarasa-Gothic/releases/download/v${ver}/Sarasa-TrueType-${ver}.7z"
    local tmpdir
    tmpdir="$(mktemp -d)"

    curl -sLo "$tmpdir/sarasa.7z" "$url" && \
    (7z x "$tmpdir/sarasa.7z" -o"$tmpdir/sarasa" -y 2>/dev/null || \
     7za x "$tmpdir/sarasa.7z" -o"$tmpdir/sarasa" -y 2>/dev/null) && \
    sudo mkdir -p /usr/local/share/fonts/sarasa-gothic && \
    sudo cp "$tmpdir"/sarasa/SarasaUISC-*.ttf /usr/local/share/fonts/sarasa-gothic/ 2>/dev/null && \
    sudo fc-cache -f && \
    ok "Sarasa Gothic instalada." || warn "Sarasa Gothic falhou. Instale manualmente."

    rm -rf "$tmpdir"
}

# ── Backup de configs existentes ─────────────────────────────
backup_existing() {
    local backup_dir="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
    local has_backup=false

    for item in "$REPO_DIR"/*; do
        local name
        name="$(basename "$item")"

        local skip=false
        for ex in "${EXCLUDE_LIST[@]}"; do
            [[ "$name" == "$ex" ]] && skip=true && break
        done
        $skip && continue

        local target="$HOME/.config/$name"

        if [[ -e "$target" || -L "$target" ]]; then
            if [[ -L "$target" ]]; then
                rm "$target"
                continue
            fi
            if [[ "$has_backup" == false ]]; then
                mkdir -p "$backup_dir"
                has_backup=true
                info "Backup em: $backup_dir"
            fi
            mv "$target" "$backup_dir/" && \
                info "  Movido: ~/.config/$name → $backup_dir/$name"
        fi
    done

    $has_backup && ok "Backup concluído." || info "Nenhum config existente para fazer backup."
}

# ── Cria links simbólicos em ~/.config ───────────────────────
sync_dotfiles() {
    info "Criando links simbólicos em ~/.config/..."
    mkdir -p "$HOME/.config"

    for item in "$REPO_DIR"/*; do
        local name
        name="$(basename "$item")"

        local skip=false
        for ex in "${EXCLUDE_LIST[@]}"; do
            [[ "$name" == "$ex" ]] && skip=true && break
        done
        $skip && continue

        ln -sfn "$item" "$HOME/.config/$name"
        ok "  $name → ~/.config/$name"
    done

    # starship.toml vai para ~/.config/starship.toml diretamente
    if [[ -f "$REPO_DIR/starship.toml" ]]; then
        ln -sfn "$REPO_DIR/starship.toml" "$HOME/.config/starship.toml"
        ok "  starship.toml → ~/.config/starship.toml"
    fi

    ok "Links criados."
}

# ── Pós-instalação ───────────────────────────────────────────
post_install() {
    info "Aplicando configurações pós-instalação..."

    # Expande HOMEPATH no hyprpaper.conf
    local hyprpaper_conf="$HOME/.config/hypr/hyprpaper.conf"
    if [[ -L "$hyprpaper_conf" ]]; then
        local src
        src="$(readlink "$hyprpaper_conf")"
        rm "$hyprpaper_conf"
        cp "$src" "$hyprpaper_conf"
    fi
    if [[ -f "$hyprpaper_conf" ]]; then
        sed -i "s|HOMEPATH|$HOME|g" "$hyprpaper_conf"
        ok "hyprpaper.conf: caminhos expandidos para $HOME"
    fi

    # Fix config.fish: guard para cachyos-fish-config (só existe no CachyOS)
    local fish_conf="$HOME/.config/fish/config.fish"
    if [[ -L "$fish_conf" ]]; then
        local src
        src="$(readlink "$fish_conf")"
        rm "$fish_conf"
        cp "$src" "$fish_conf"
    fi

    if [[ -f "$fish_conf" ]] && grep -q "source /usr/share/cachyos-fish-config" "$fish_conf"; then
        python3 - "$fish_conf" << 'PYFIX'
import sys
path = sys.argv[1]
lines = open(path).readlines()
out = []
for line in lines:
    stripped = line.rstrip()
    if stripped == "source /usr/share/cachyos-fish-config/cachyos-config.fish":
        out.append("if test -f /usr/share/cachyos-fish-config/cachyos-config.fish\n")
        out.append("    source /usr/share/cachyos-fish-config/cachyos-config.fish\n")
        out.append("end\n")
    else:
        out.append(line)
text = "".join(out)
if "fish_greeting" not in text:
    text += """
function fish_greeting
    if not test -f /usr/share/cachyos-fish-config/cachyos-config.fish
        if command -q fastfetch
            fastfetch
        end
    end
end
"""
open(path, "w").write(text)
PYFIX
        ok "config.fish: guard para cachyos-fish-config adicionado."
    fi

    # Fisher + plugins de autocomplete
    if command -v fish &>/dev/null; then
        info "Instalando fisher e plugins..."
        fish -c "
            if not functions -q fisher
                curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
                fisher install jorgebucaran/fisher
            end
            fisher install PatrickF1/fzf.fish 2>/dev/null || true
            fisher install franciscolourenco/done 2>/dev/null || true
            fisher install jorgebucaran/autopair.fish 2>/dev/null || true
        " 2>/dev/null || warn "Fisher/plugins: verifique manualmente."
        ok "fisher e plugins instalados."

        # fzf para o fzf.fish funcionar
        if ! command -v fzf &>/dev/null; then
            sudo pacman -S --needed --noconfirm fzf 2>/dev/null || true
        fi
    fi

    # Permissões dos scripts da waybar
    if [[ -d "$HOME/.config/waybar" ]]; then
        find "$HOME/.config/waybar" -name "*.sh" -o -name "*.py" | xargs chmod +x 2>/dev/null || true
        ok "Permissões dos scripts da waybar aplicadas."
    fi

    # Define fish como shell padrão
    if command -v fish &>/dev/null; then
        local fish_path
        fish_path="$(command -v fish)"
        local real_user
        real_user="$(logname 2>/dev/null || id -un)"
        if [[ "$SHELL" != "$fish_path" ]]; then
            info "Definindo fish como shell padrão..."
            grep -qF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells
            sudo usermod -s "$fish_path" "$real_user" || warn "Não foi possível definir fish como padrão."
        fi
    fi

    # Recarrega Hyprland se estiver rodando
    if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null 2>&1; then
        info "Recarregando Hyprland..."
        hyprctl reload || warn "hyprctl reload falhou."
    fi

    # Reinicia ou inicia Waybar
    if pgrep -x waybar &>/dev/null; then
        info "Reiniciando Waybar..."
        pkill waybar || true
        sleep 0.5
    fi
    if command -v waybar &>/dev/null; then
        waybar 2>/tmp/waybar-install.log & disown
        sleep 1
        pgrep -x waybar &>/dev/null \
            && ok "Waybar iniciado." \
            || warn "Waybar não iniciou. Veja erros em /tmp/waybar-install.log"
    fi

    ok "Pós-instalação concluída."

    echo ""
    warn "═══════════════════════════════════════════════════"
    warn "  ATENÇÃO — Configuração manual necessária:"
    warn "═══════════════════════════════════════════════════"
    warn "  1. waybar/modules/mail.py depende de 'mailsecrets.py'"
    warn "     Crie ~/.config/waybar/modules/mailsecrets.py com:"
    warn "       username = 'seu@email.com'"
    warn "       password = 'sua_senha_ou_app_password'"
    warn "       server   = 'imap.seuservidor.com'"
    warn "  2. config.fish carrega cachyos-fish-config só no CachyOS"
    warn "     (no Arch puro a linha é ignorada automaticamente)"
    warn "═══════════════════════════════════════════════════"
}

# ── Confirmação do usuário ───────────────────────────────────
confirm() {
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  DOTFILES INSTALLER — KauaRios${NC}"
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Repo:    ${BOLD}$REPO_DIR${NC}"
    echo -e "  Destino: ${BOLD}~/.config/${NC}"
    echo -e "  Distro:  ${BOLD}${DISTRO_ID:-desconhecida}${NC}"
    echo -e "  PKG MGR: ${BOLD}pacman (sem AUR helper)${NC}"
    echo ""
    warn "Configs existentes serão movidos para backup antes de sobrescrever."
    echo ""
    ask "Iniciar instalação? [s/N]"
    local resp
    safe_read resp "n"
    [[ "$resp" =~ ^[Ss]$ ]] || { info "Instalação cancelada."; exit 0; }
}

# ── Main ─────────────────────────────────────────────────────
main() {
    check_requirements
    confirm
    install_packages
    backup_existing
    sync_dotfiles
    post_install

    echo ""
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Setup concluído com sucesso!${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
    echo ""
    info "Se o áudio não funcionar: ${BOLD}wpctl set-default 51${NC}"
    info "Reinicie a sessão para aplicar todas as mudanças."
}

main "$@"
