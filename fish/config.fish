starship init fish | source

# Carrega config do CachyOS apenas se existir (não quebra em Arch puro)
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# Greeting: fastfetch em Arch puro, no CachyOS já é chamado pelo cachyos-config
function fish_greeting
    if not test -f /usr/share/cachyos-fish-config/cachyos-config.fish
        if command -q fastfetch
            fastfetch
        end
    end
end