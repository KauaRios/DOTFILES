#!/bin/bash

# Cores para o terminal (estética Catppuccin)
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Iniciando a instalação do setup do Anaya...${NC}"

# Instala os pacotes listados no requirements.txt
sudo pacman -S --needed - < requirements.txt

# Cria os links simbólicos para a pasta .config
# Isso evita que você tenha que copiar os arquivos manualmente
echo -e "${BLUE}Linkando as dotfiles...${NC}"
cp -rv .config/* ~/.config/

# Mensagem final
echo -e "${BLUE}Setup concluído! Lembre-se de rodar 'wpctl set-default' se o áudio falhar.${NC}"