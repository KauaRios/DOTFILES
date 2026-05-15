--------------------
---- MONITORES  ----
--------------------

-- Tela do notebook (1920x1080) na esquerda
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = 1,
})

-- Monitor HDMI (1440x900) na direita
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1440x900@59.89",
    position = "1921x0", -- workaround bug 0.55: +1px libera cursor pro 2o monitor
    scale    = 1,
})

-- Regra coringa (não apague)
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Workspace 1 padrão no HDMI
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
