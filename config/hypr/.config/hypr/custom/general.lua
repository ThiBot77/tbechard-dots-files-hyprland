-- Charge apres hyprland/general.lua : ce qui est ici gagne.

-- end-4 force kb_layout = "us".
hl.config({
    input = {
        kb_layout = "fr,us",
        kb_options = "grp:win_space_toggle",
    }
})

-- end-4 active clickfinger_behavior : l'appui physique compte les doigts au
-- lieu de regarder ou on appuie, donc le coin bas-droit rendait un clic gauche.
hl.config({
    input = {
        touchpad = {
            clickfinger_behavior = false,
        }
    }
})
