hl.on("hyprland.start", function()
    -- Agent de secrets NetworkManager.
    --
    -- Sans agent enregistre, NetworkManager n'a personne a qui demander les
    -- secrets d'une connexion et abandonne aussitot :
    --   vpn[...,"arcacloud"]: secrets: failed to request VPN secrets #3:
    --   No agents were available for this request.
    --
    -- WireGuard n'est pas concerne (ses cles vivent dans le profil), mais
    -- l'OpenVPN du boulot a challenge-response-flags = 2, donc le code MFA
    -- doit etre saisi a chaque connexion : il faut une fenetre pour le taper.
    -- Une session Plasma aurait plasma-nm, GNOME son propre agent ; sous
    -- Hyprland il n'y en a aucun, d'ou nm-applet.
    hl.exec_cmd("nm-applet")
end)
