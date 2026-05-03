# ~/.config/fish/config.fish

# 1. Remove a mensagem padrão chata do Fish



set -g fish_greeting



# 2. Tenta carregar as otimizações do CachyOS (se o usuário estiver no CachyOS)
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# 3. GARANTE o Fastfetch em qualquer distro (Arch, Fedora, VM, etc)
# Só roda se o fastfetch estiver instalado e se NÃO estiver no CachyOS
# (para evitar que apareça duas vezes no CachyOS)
if command -q fastfetch
    if not test -f /usr/share/cachyos-fish-config/cachyos-config.fish
        fastfetch
    end
end

# Suas outras configs (starship, aliases, etc)
starship init fish | source
