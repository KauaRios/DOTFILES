# ❄️ dotfiles

> O repositório onde guardo a minha casa virtual. Minhas dotfiles e personalizações do Hyprland utilizando o CachyOS.

---

### 💻 Setup
*   **OS:** [CachyOS](https://cachyos.org/) (Arch Based)
*   **WM:** Hyprland
*   **Shell:** Fish + Starship
*   **Terminais:** Alacritty / Kitty
*   **Editor:** Micro / VS Code
*   **Estética:** Catppuccin Mocha / Dark Anime

---

### 📁 Estrutura de Configurações
| Componente | Descrição |
| :--- | :--- |
| `hypr/` | Configurações principais do Hyprland e Hyprpaper |
| `waybar/` | Barra superior personalizada (CachyOS style) |
| `wofi/` | Launcher de aplicativos |
| `mako/` | Notificações do sistema |
| `fastfetch/` | Informações do sistema com artes personalizadas |
| `alacritty/` | Terminal principal focado em performance |
| `fish/` | Shell interativo com syntax highlighting |
| `swaylock/` | Tela de bloqueio estética |

---

### 🚀 Como usar
Se você quiser replicar partes desse setup, certifique-se de ter as dependências instaladas (especialmente o pacote de ferramentas do CachyOS) e copie a pasta desejada para seu `~/.config/`:

```bash
# Exemplo para o Waybar
cp -r .config/waybar ~/.config/

---

### Dica:
Para salvar esse arquivo pelo terminal do VS Code, você pode rodar:
`git add README.md`
`git commit -m "docs: add README with project description"`
`git push`