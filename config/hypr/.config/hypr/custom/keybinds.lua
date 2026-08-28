hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Envoyer la fenetre vers un workspace : SUPER+SHIFT+<chiffre>, plus pratique
-- que le SUPER+ALT+<chiffre> d'end-4 (qui reste dispo).
-- Les codes bruts doublent les keysyms car en AZERTY les chiffres sont sur le
-- niveau shift : selon le contexte Hyprland voit "1" ou "ampersand".
for i = 1, 10 do
    local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
    hl.bind("SUPER + SHIFT + " .. (i % 10), function()
        hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
    end, { description = "Window: Send to workspace " .. i })
    hl.bind("SUPER + SHIFT + code:" .. numberkey[i], function()
        hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
    end)
end
