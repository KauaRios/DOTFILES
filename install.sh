#!/bin/bash

# Cores para o terminal (estética Catppuccin Mocha)
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Iniciando a instalação do setup do Kauã...${NC}"

# 1. Instalação das dependências (Prioridade: Yay > Paru > Pacman)
if command -v yay &> /dev/null; then
    echo -e "${BLUE}Usando yay...${NC}"
    yay -S --needed - < requirements.txt
elif command -v paru &> /dev/null; then
    echo -e "${BLUE}Usando paru...${NC}"
    paru -S --needed - < requirements.txt
else
    echo -e "${BLUE}Usando pacman...${NC}"
    sudo pacman -S --needed - < requirements.txt
fi


# 2. Sincronização Dinâmica com a ~/.config
echo -e "${BLUE}Sincronizando arquivos do repositório com ~/.config...${NC}"

# O loop 'for *' percorre todos os arquivos e pastas na raiz do  repo
for item in *; do
    # Lista de exclusão: arquivos que NÃO devem ir para a .config
    if [[ "$item" == "install.sh" || "$item" == "requirements.txt" || "$item" == "README.md" || "$item" == ".gitignore" || "$item" == "LICENSE" || "$item" == ".git" ]]; then
        continue
    fi

    # Copia o restante (pastas como hypr, kitty, etc. e arquivos como starship.toml)
    echo -e "Copiando $item para ~/.config/..."
    cp -rv "$item" ~/.config/
done

# 3. Reload do Ambiente
echo -e "${BLUE}Aplicando configurações...${NC}"
hyprctl reload
pkill -USR2 waybar || waybar & 

echo -e "${BLUE}Setup concluído! Audio: wpctl set-default 51${NC}"