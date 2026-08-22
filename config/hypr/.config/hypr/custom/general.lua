-- Overrides personnels. Ce fichier est prevu par end-4 et charge apres
-- hyprland/general.lua, donc ce qui est ici gagne.

-- Clavier : end-4 force kb_layout = "us". On remet le francais en premier,
-- avec l'americain en second pour pouvoir basculer.
hl.config({
    input = {
        kb_layout = "fr,us",
        kb_options = "grp:win_space_toggle",
    }
})
