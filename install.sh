#!/bin/bash
# ============================================================
#  DOTFILES INSTALLER — KauaRios/DOTFILES
#  Suporte: Arch Linux, CachyOS, Fedora, openSUSE Tumbleweed,
#           Debian, Ubuntu e derivados
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
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERRO]${NC}  $*" >&2; exit 1; }
ask()     { echo -e "${BOLD}$*${NC}"; }

# Lê uma resposta do usuário de forma segura (trata EOF/Ctrl+D)
safe_read() {
    local var_name="$1"
    local default="${2:-}"
    if ! IFS= read -r "$var_name" 2>/dev/null; then
        # EOF (Ctrl+D): usa o valor padrão
        printf -v "$var_name" '%s' "$default"
    fi
}

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Lista de arquivos/pastas do repo que NÃO vão para ~/.config ──
# (usada tanto no backup quanto na sincronização)
EXCLUDE_LIST=("install.sh" "requirements.txt" "README.md" ".gitignore" "LICENSE" ".git" "assets" "starship.toml")

# ── Verificações iniciais ────────────────────────────────────
check_requirements() {
    info "Verificando dependências básicas do instalador..."

    for cmd in git curl sudo; do
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

    ok "Verificações básicas OK."
}

# ── Detecção de distro ───────────────────────────────────────
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_LIKE="${ID_LIKE:-}"
    else
        error "Não foi possível detectar a distribuição (/etc/os-release não encontrado)."
    fi

    # Normaliza para família
    if echo "$DISTRO_ID $DISTRO_LIKE" | grep -qiE "arch|cachyos|endeavour|manjaro|garuda"; then
        DISTRO_FAMILY="arch"
    elif echo "$DISTRO_ID $DISTRO_LIKE" | grep -qiE "fedora|rhel|centos|nobara"; then
        DISTRO_FAMILY="fedora"
    elif echo "$DISTRO_ID $DISTRO_LIKE" | grep -qiE "opensuse|suse"; then
        DISTRO_FAMILY="opensuse"
    elif echo "$DISTRO_ID $DISTRO_LIKE" | grep -qiE "debian|ubuntu|mint|pop|elementary|zorin"; then
        DISTRO_FAMILY="debian"
    else
        warn "Distribuição '$DISTRO_ID' não reconhecida explicitamente."
        DISTRO_FAMILY="unknown"
    fi

    info "Distro detectada: ${BOLD}$DISTRO_ID${NC} (família: $DISTRO_FAMILY)"
}

# ── Instalação de pacotes por distro ─────────────────────────

# Pacotes Arch (nomes do AUR/pacman)
PKGS_ARCH=(
    hyprland hyprlock hyprpaper
    waybar wofi mako wlogout
    kitty alacritty fish starship fastfetch
    pipewire wireplumber pavucontrol brightnessctl
    playerctl btop rofi hyprshot grim slurp wl-clipboard
    # Fontes usadas nos configs
    ttf-jetbrains-mono-nerd   # kitty.conf
    cantarell-fonts            # hyprlock.conf
    ttf-fira-sans              # waybar/style.css
    otf-font-awesome           # waybar/style.css
    ttf-hack-nerd              # wofi/style.css
    ttf-sarasa-gothic          # mako/config (AUR)
)

# Pacotes Fedora (nomes dnf)
# hyprlock e wlogout são instalados via COPR solopasha/hyprland
PKGS_FEDORA=(
    hyprland hyprlock hyprpaper
    waybar wofi mako wlogout
    kitty alacritty fish
    pipewire wireplumber pavucontrol brightnessctl
    playerctl btop rofi grim slurp wl-clipboard
    # Fontes
    jetbrains-mono-fonts-all   # kitty.conf
    google-cantarell-fonts     # hyprlock.conf
    fira-sans-fonts            # waybar/style.css
    fontawesome-fonts          # waybar/style.css
    hack-fonts                 # wofi/style.css
    # Sarasa Gothic (mako): instalada via _install_sarasa_gothic abaixo
)

# Pacotes openSUSE Tumbleweed
# hyprlock disponível em security:privacy, wlogout em home:Dead_Mozay
PKGS_OPENSUSE=(
    hyprland hyprlock hyprpaper
    waybar wofi mako wlogout
    kitty alacritty fish
    pipewire wireplumber pavucontrol brightnessctl
    playerctl btop rofi grim slurp wl-clipboard
    # Fontes
    jetbrains-mono-fonts       # kitty.conf
    google-cantarell-fonts     # hyprlock.conf
    google-fira-fonts          # waybar/style.css
    fontawesome-fonts          # waybar/style.css
    hack-fonts                 # wofi/style.css
    # Sarasa Gothic (mako): instalada via _install_sarasa_gothic abaixo
)

# Pacotes Debian/Ubuntu (via apt — muitos via backports ou PPAs)
# Nota: hyprland, hyprlock e wlogout no Debian requerem build manual ou PPA externo
PKGS_DEBIAN=(
    waybar wofi mako-notifier
    kitty alacritty fish
    pipewire wireplumber pavucontrol brightnessctl
    playerctl btop rofi grim slurp wl-clipboard
    # Fontes
    fonts-jetbrains-mono       # kitty.conf
    fonts-cantarell            # hyprlock.conf
    fonts-firacode             # waybar/style.css (fira)
    fonts-font-awesome         # waybar/style.css
    fonts-hack                 # wofi/style.css
    # Sarasa Gothic (mako): instalada via _install_sarasa_gothic abaixo
)

install_packages() {
    info "Iniciando instalação de pacotes para família: $DISTRO_FAMILY"

    case "$DISTRO_FAMILY" in
        arch)
            # Prefere yay > paru > pacman
            if command -v yay &>/dev/null; then
                PKG_MGR="yay"
                PKG_CMD="yay -S --needed --noconfirm"
            elif command -v paru &>/dev/null; then
                PKG_MGR="paru"
                PKG_CMD="paru -S --needed --noconfirm"
            else
                PKG_MGR="pacman"
                PKG_CMD="sudo pacman -S --needed --noconfirm"
                warn "yay/paru não encontrados — usando pacman (pacotes AUR serão pulados)."
            fi
            info "Gerenciador: $PKG_MGR"
            $PKG_CMD "${PKGS_ARCH[@]}" || warn "Alguns pacotes falharam — verifique manualmente."
            ;;

        fedora)
            info "Instalando via dnf..."
            # Habilita copr do solopasha — contém hyprland, hyprlock e wlogout
            if ! sudo dnf copr list --enabled 2>/dev/null | grep -q "solopasha/hyprland"; then
                info "Habilitando COPR solopasha/hyprland..."
                sudo dnf copr enable -y solopasha/hyprland 2>/dev/null || \
                    warn "Não foi possível habilitar o COPR. Hyprland, hyprlock e wlogout podem não ser instalados."
            fi
            sudo dnf install -y "${PKGS_FEDORA[@]}" || warn "Alguns pacotes falharam."
            # Starship via script oficial
            if ! command -v starship &>/dev/null; then
                info "Instalando Starship..."
                curl -sS https://starship.rs/install.sh | sh -s -- -y || warn "Starship falhou."
            fi
            # Fastfetch: busca versão mais recente dinamicamente
            if ! command -v fastfetch &>/dev/null; then
                _install_fastfetch "rpm"
            fi
            # Sarasa Gothic (mako) — não está nos repos do Fedora
            _install_sarasa_gothic
            ;;

        opensuse)
            info "Instalando via zypper..."
            # Adiciona repositórios OBS para hyprlock e wlogout se necessário
            if ! zypper repos 2>/dev/null | grep -qi "security:privacy"; then
                info "Adicionando repo OBS security:privacy (hyprlock)..."
                sudo zypper addrepo -f \
                    "https://download.opensuse.org/repositories/security:privacy/openSUSE_Tumbleweed/" \
                    security-privacy 2>/dev/null || warn "Não foi possível adicionar repo do hyprlock."
            fi
            sudo zypper install -y "${PKGS_OPENSUSE[@]}" || warn "Alguns pacotes falharam."
            if ! command -v starship &>/dev/null; then
                curl -sS https://starship.rs/install.sh | sh -s -- -y || warn "Starship falhou."
            fi
            if ! command -v fastfetch &>/dev/null; then
                _install_fastfetch "rpm"
            fi
            # Sarasa Gothic (mako) — não está nos repos do openSUSE
            _install_sarasa_gothic
            ;;

        debian)
            info "Instalando via apt..."
            sudo apt-get update -qq
            sudo apt-get install -y "${PKGS_DEBIAN[@]}" || warn "Alguns pacotes falharam."
            if ! command -v starship &>/dev/null; then
                curl -sS https://starship.rs/install.sh | sh -s -- -y || warn "Starship falhou."
            fi
            if ! command -v fastfetch &>/dev/null; then
                _install_fastfetch "deb"
            fi
            # Sarasa Gothic (mako) — não está nos repos do Debian/Ubuntu
            _install_sarasa_gothic
            warn "Hyprland, hyprlock e wlogout no Debian/Ubuntu requerem instalação manual ou PPA externo."
            warn "Veja: https://github.com/hyprwm/Hyprland"
            ;;

        *)
            warn "Distro não suportada automaticamente. Instale os pacotes manualmente."
            warn "Lista de referência (nomes Arch): ${PKGS_ARCH[*]}"
            ;;
    esac

    ok "Pacotes processados."
}

# ── Instala fastfetch buscando a versão mais recente ────────
_install_fastfetch() {
    local pkg_type="$1"   # "rpm" ou "deb"
    info "Buscando versão mais recente do fastfetch..."

    local latest_ver
    latest_ver="$(curl -s "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" \
        | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')" || true

    if [[ -z "$latest_ver" ]]; then
        warn "Não foi possível obter a versão mais recente do fastfetch via API. Pulando."
        return
    fi

    info "Instalando fastfetch ${latest_ver}..."
    if [[ "$pkg_type" == "rpm" ]]; then
        curl -sLo /tmp/fastfetch.rpm \
            "https://github.com/fastfetch-cli/fastfetch/releases/download/${latest_ver}/fastfetch-linux-amd64.rpm" && \
        sudo rpm -i /tmp/fastfetch.rpm || warn "Fastfetch falhou."
    else
        curl -sLo /tmp/fastfetch.deb \
            "https://github.com/fastfetch-cli/fastfetch/releases/download/${latest_ver}/fastfetch-linux-amd64.deb" && \
        sudo dpkg -i /tmp/fastfetch.deb || warn "Fastfetch falhou."
    fi
}

# ── Instala Sarasa Gothic (fonte do mako) nas distros sem repo ──
# Arch instala via AUR (ttf-sarasa-gothic), as demais baixam do GitHub
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
        warn "Não foi possível obter versão da Sarasa Gothic. Instale manualmente."
        warn "https://github.com/be5invis/Sarasa-Gothic/releases"
        return
    fi

    info "Instalando Sarasa Gothic ${ver} (fonte usada no mako)..."
    local url="https://github.com/be5invis/Sarasa-Gothic/releases/download/v${ver}/Sarasa-TrueType-${ver}.7z"
    local tmpdir
    tmpdir="$(mktemp -d)"

    # Precisa de p7zip para extrair
    if ! command -v 7z &>/dev/null && ! command -v 7za &>/dev/null; then
        warn "p7zip não encontrado — tentando instalar..."
        case "$DISTRO_FAMILY" in
            fedora)   sudo dnf install -y p7zip p7zip-plugins || true ;;
            opensuse) sudo zypper install -y p7zip || true ;;
            debian)   sudo apt-get install -y p7zip-full || true ;;
        esac
    fi

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

        # Pula exclusões definidas em EXCLUDE_LIST
        local skip=false
        for ex in "${EXCLUDE_LIST[@]}"; do
            [[ "$name" == "$ex" ]] && skip=true && break
        done
        $skip && continue

        local target="$HOME/.config/$name"
        if [[ -e "$target" ]]; then
            if [[ "$has_backup" == false ]]; then
                mkdir -p "$backup_dir"
                has_backup=true
                info "Backup dos configs existentes em: $backup_dir"
            fi
            cp -r "$target" "$backup_dir/" && \
                info "  Backup: ~/.config/$name → $backup_dir/$name"
        fi
    done

    $has_backup && ok "Backup concluído." || info "Nenhum config existente para fazer backup."
}

# ── Sincronização dos dotfiles ───────────────────────────────
sync_dotfiles() {
    info "Sincronizando dotfiles para ~/.config/..."

    mkdir -p "$HOME/.config"

    for item in "$REPO_DIR"/*; do
        local name
        name="$(basename "$item")"

        # Pula exclusões definidas em EXCLUDE_LIST
        local skip=false
        for ex in "${EXCLUDE_LIST[@]}"; do
            [[ "$name" == "$ex" ]] && skip=true && break
        done
        $skip && continue

        # starship.toml vai para ~/.config/starship.toml diretamente
        if [[ "$name" == "starship.toml" ]]; then
            cp -v "$item" "$HOME/.config/starship.toml"
            continue
        fi

        cp -rv "$item" "$HOME/.config/"
        ok "  Copiado: $name"
    done

    ok "Sincronização concluída."
}

# ── Configurações pós-instalação ─────────────────────────────
post_install() {
    info "Aplicando configurações pós-instalação..."

    # Define fish como shell padrão se não for
    if command -v fish &>/dev/null; then
        local fish_path
        fish_path="$(command -v fish)"
        if [[ "$SHELL" != "$fish_path" ]]; then
            info "Definindo fish como shell padrão..."
            # Garante que fish está em /etc/shells
            grep -qF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells
            chsh -s "$fish_path" || warn "Não foi possível definir fish como padrão. Rode: chsh -s $fish_path"
        fi
    fi

    # Recarrega Hyprland se estiver rodando
    if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null 2>&1; then
        info "Recarregando Hyprland..."
        hyprctl reload || warn "hyprctl reload falhou."
    fi

    # Reinicia Waybar
    if pgrep -x waybar &>/dev/null; then
        info "Reiniciando Waybar..."
        pkill waybar || true
        sleep 0.5
        waybar 2>/tmp/waybar-install.log & disown
        sleep 1
        if ! pgrep -x waybar &>/dev/null; then
            warn "Waybar não iniciou. Verifique erros em /tmp/waybar-install.log"
        fi
    elif command -v waybar &>/dev/null; then
        info "Iniciando Waybar..."
        waybar 2>/tmp/waybar-install.log & disown
        sleep 1
        if ! pgrep -x waybar &>/dev/null; then
            warn "Waybar não iniciou. Verifique erros em /tmp/waybar-install.log"
        fi
    fi

    ok "Pós-instalação concluída."

    echo ""
    warn "═══════════════════════════════════════════════════"
    warn "  ATENÇÃO — Itens que precisam de configuração manual:"
    warn "═══════════════════════════════════════════════════"
    warn "  1. waybar/modules/mail.py depende de 'mailsecrets.py'"
    warn "     Crie ~/.config/waybar/modules/mailsecrets.py com:"
    warn "       username = 'seu@email.com'"
    warn "       password = 'sua_senha_ou_app_password'"
    warn "       server   = 'imap.seuservidor.com'"
    warn "  2. fish/config.fish só carrega cachyos-fish-config no CachyOS"
    warn "     (nas outras distros a linha é ignorada automaticamente)"
    warn "═══════════════════════════════════════════════════"
}

# ── Confirmação do usuário ───────────────────────────────────
confirm() {
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  DOTFILES INSTALLER — KauaRios${NC}"
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Repo:   ${BOLD}$REPO_DIR${NC}"
    echo -e "  Destino: ${BOLD}~/.config/${NC}"
    echo -e "  Distro: ${BOLD}${DISTRO_ID:-desconhecida}${NC}"
    echo ""
    warn "Configs existentes serão copiados para backup antes de sobrescrever."
    echo ""
    ask "Iniciar instalação? [s/N]"
    local resp
    safe_read resp "n"
    [[ "$resp" =~ ^[Ss]$ ]] || { info "Instalação cancelada."; exit 0; }
}

# ── Main ─────────────────────────────────────────────────────
main() {
    check_requirements
    detect_distro
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