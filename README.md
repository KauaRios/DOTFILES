<div align="center">

# 🌌 dotfiles


**TESTADO EM ARCHLINUX E CACHYOS TOTALMENTE FUNCIONAL**

**Setup pessoal do Hyprland rodando no CachyOS** 
*Simples, funcional e agradável aos olhos.*

![Preview](assets/AREA.png)


[![CachyOS](https://img.shields.io/badge/OS-CachyOS-blue?style=for-the-badge&logo=archlinux&logoColor=white)](https://cachyos.org/)
[![Hyprland](https://img.shields.io/badge/WM-Hyprland-58e1ff?style=for-the-badge)](https://hyprland.org/)
[![Fish](https://img.shields.io/badge/Shell-Fish-4abaff?style=for-the-badge&logo=fish&logoColor=white)](https://fishshell.com/)
[![License](https://img.shields.io/badge/License-MIT-purple?style=for-the-badge)](LICENSE)

</div>

---

## 💻 Setup

| Componente | Ferramenta |
|---|---|
| 🐧 **Sistema Operacional** | [CachyOS](https://cachyos.org/) (Arch-based) |
| 🪟 **Window Manager** | [Hyprland](https://hyprland.org/) |
| 🐟 **Shell** | [Fish](https://fishshell.com/) + [Starship](https://starship.rs/) |
| 📟 **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) / [Alacritty](https://alacritty.org/) |
| ✏️ **Editor** | [Micro](https://micro-editor.github.io/) / VS Code |
| 🔔 **Notificações** | [Mako](https://github.com/emersion/mako) |
| 🎨 **Tema** | Catppuccin Mocha / Dark Anime |
| 🔒 **Tela de Bloqueio** | [Hyprlock](https://github.com/hyprwm/hyprlock) |
| 🚀 **Launcher** | [Wofi](https://hg.sr.ht/~scoopta/wofi) |
| 📊 **Monitor do sistema** | [btop](https://github.com/aristocratos/btop) |

---

## 📁 Estrutura

```
~/.config/
├── hypr/          # Configurações do Hyprland + Hyprpaper + Hyprlock
│   └── scripts/   # screenshot_full e screenshot_area (grim + slurp)
├── waybar/        # Barra de status personalizada
│   └── modules/   # weather.sh, spotify.sh, storage.sh, mail.py
├── wofi/          # Launcher de aplicativos
├── mako/          # Notificações do sistema
├── swaylock/      # Tela de bloqueio (swaylock)
├── wlogout/       # Menu de logout
├── kitty/         # Terminal Kitty
├── alacritty/     # Terminal Alacritty
├── fish/          # Configurações do shell Fish
├── fastfetch/     # Info do sistema com arte ASCII
├── btop/          # Monitor de sistema
├── micro/         # Editor de texto Micro
└── wallpapers/    # Wallpapers (usado pelo hyprpaper)
```

---

## 📦 Dependências

Todos os pacotes necessários estão no arquivo [`requirements.txt`](requirements.txt):

```
hyprland  hyprlock  hyprpaper  waybar     wofi
mako      wlogout   kitty      alacritty  fish
starship  fastfetch pipewire   wireplumber
brightnessctl  pavucontrol  playerctl
btop      rofi      grim       slurp      wl-clipboard
ttf-jetbrains-mono-nerd  cantarell-fonts  ttf-sarasa-gothic
```

> **Nota:** `waybar/modules/mail.py` requer um arquivo `mailsecrets.py` local (não incluso) com suas credenciais IMAP. Veja o cabeçalho do arquivo para instruções.

---

## 🚀 Instalação

### Automática (recomendado)

```bash
git clone https://github.com/KauaRios/DOTFILES.git
cd DOTFILES
chmod +x install.sh
./install.sh
```

### Manual

Clone o repositório e copie as pastas desejadas para `~/.config/`:

```bash
git clone https://github.com/KauaRios/DOTFILES.git
cd DOTFILES

# Copiar todas as configurações de uma vez
cp -r hypr waybar wofi mako swaylock wlogout kitty alacritty fish fastfetch micro ~/.config/

# Ou copiar individualmente — exemplo para o Waybar:
cp -r waybar ~/.config/

# starship.toml vai diretamente para ~/.config/
cp starship.toml ~/.config/
```

> ⚠️ **Atenção:** Faça backup das suas configurações atuais antes de copiar.  
> ```bash
> cp -r ~/.config/hypr ~/.config/hypr.bak
> ```

---

## 🎨 Temas & Estética

O setup utiliza o tema **Catppuccin Mocha** como base, com toques de estética *dark anime*. Os principais componentes visuais são:

- **Waybar** — barra superior com módulos de sistema, workspaces e relógio
- **Wofi** — launcher minimalista com fundo translúcido
- **Mako** — notificações com bordas arredondadas e cores suaves
- **Swaylock** — tela de bloqueio com blur e overlay escuro
- **Fastfetch** — exibição de info do sistema com arte personalizada

---

## 🔧 Pós-instalação

Após instalar, reinicie o Hyprland ou recarregue as configurações:

```bash
# Recarregar Hyprland
hyprctl reload

# Recarregar Waybar
pkill waybar && waybar &

# Recarregar Mako
pkill mako && mako &
```

---

## 📄 Licença

Distribuído sob a licença MIT. Veja [`LICENSE`](LICENSE) para mais informações.

---

<div align="center">

Feito com 🖤 por [KauaRios](https://github.com/KauaRios)

</div>
