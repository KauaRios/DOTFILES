---------------------
---- LAYOUTS      ----
---------------------

hl.config({
    dwindle = {
        preserve_split = true,
   
    },
    master = {
        new_status = "master",
    },
    scrolling = {
        fullscreen_on_one_column = true,
    },
})


----------------
----  MISC   ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = false,
    },
    cursor = {
        no_hardware_cursors = true,  -- resolve stuttering entre monitores de refresh diferente (144hz vs 60hz)
        no_warps = false,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "br",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = -0.80,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Gesto de 3 dedos para trocar workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Config por dispositivo
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})