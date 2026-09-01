hl.on("hyprland.start", function()
    -- Agent de secrets NetworkManager : Hyprland n'en fournit aucun, et sans
    -- lui les connexions a secret echouent (MFA de l'OpenVPN du boulot).
    hl.exec_cmd("nm-applet")
end)
