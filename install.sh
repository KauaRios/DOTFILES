#!/bin/bash

# Cores para o terminal (estética Catppuccin Mocha)
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Iniciando a instalação do setup do Kauã...${NC}"

# 1. Lógica de instalação com prioridade para AUR Helpers
if command -v yay &> /dev/null; then
    echo -e "${BLUE}Usando yay para instalar dependências...${NC}"
    yay -S --needed - < requirements.txt
elif command -v paru &> /dev/null; then
    echo -e "${BLUE}Usando paru para instalar dependências...${NC}"
    paru -S --needed - < requirements.txt
else
    echo -e "${BLUE}AUR helper não encontrado. Usando pacman...${NC}"
    sudo pacman -S --needed - < requirements.txt
fi

# 2. Linkando as dotfiles para a pasta .config do usuário
echo -e "${BLUE}Linkando as dotfiles para ~/.config...${NC}"
cp -rv .config/* ~/.config/

# 3. Recarrega a interface em tempo real (Hyprland e Waybar)
echo -e "${BLUE}Aplicando configurações em tempo real...${NC}"
hyprctl reload
pkill -USR2 waybar || waybar & 

echo -e "${BLUE}Setup concluído, Kauã! Lembre-se do 'wpctl set-default 51' se necessário.${NC}"