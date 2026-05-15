-------------------
---- AUTOSTART ----
-------------------


hl.on("hyprland.start", function()
-- Bar + wallpaper
hl.exec_cmd("waybar")
hl.exec_cmd("hyprpaper")

-- Notificações
hl.exec_cmd("mako")
hl.exec_cmd("sleep 3 && hyprctl reload")





-- Tema GTK escuro
hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
hl.exec_cmd("xsettingsd")
end)
