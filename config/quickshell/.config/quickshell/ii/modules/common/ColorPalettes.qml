pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * Catalogue de palettes nommees.
 *
 * Une palette n'est pas un jeu de couleurs fige : c'est un couple (couleur
 * source, algorithme Material You). matugen derive ensuite les ~40 roles de
 * couleur du shell a partir de ces deux valeurs, ce qui garde les contrastes
 * corrects en clair comme en sombre.
 *
 * accent vide = la couleur est prise dans le fond d'ecran, comportement
 * d'origine d'end-4.
 *
 * Les palettes de couleur utilisent scheme-fidelity : expressive et
 * fruit-salad decalent volontairement la teinte, au point qu'une source rose
 * ressortait bleue.
 */
Singleton {
    readonly property list<var> list: [
        {
            "name": "wallpaper",
            "displayName": "Fond d'ecran",
            "accent": "",
            "type": "auto",
            "swatch": "#7E7E7E"
        },
        {
            "name": "graphite",
            "displayName": "Graphite",
            "accent": "#8A8A8A",
            "type": "scheme-monochrome",
            "swatch": "#8A8A8A"
        },
        {
            "name": "cyberpunk",
            "displayName": "Cyberpunk",
            "accent": "#FF2E88",
            "type": "scheme-fidelity",
            "swatch": "#FF2E88"
        },
        {
            "name": "matrix",
            "displayName": "Matrix",
            "accent": "#00E676",
            "type": "scheme-fidelity",
            "swatch": "#00E676"
        },
        {
            "name": "nord",
            "displayName": "Nord",
            "accent": "#88C0D0",
            "type": "scheme-fidelity",
            "swatch": "#88C0D0"
        },
        {
            "name": "dracula",
            "displayName": "Dracula",
            "accent": "#BD93F9",
            "type": "scheme-fidelity",
            "swatch": "#BD93F9"
        },
        {
            "name": "ember",
            "displayName": "Braise",
            "accent": "#FF6E40",
            "type": "scheme-fidelity",
            "swatch": "#FF6E40"
        },
        {
            "name": "gold",
            "displayName": "Or",
            "accent": "#E5B567",
            "type": "scheme-fidelity",
            "swatch": "#E5B567"
        },
        {
            "name": "lagoon",
            "displayName": "Lagon",
            "accent": "#26C6DA",
            "type": "scheme-fidelity",
            "swatch": "#26C6DA"
        },
        {
            "name": "sakura",
            "displayName": "Sakura",
            "accent": "#FF8FAB",
            "type": "scheme-fidelity",
            "swatch": "#FF8FAB"
        }
    ]

    function byName(name) {
        return list.find(p => p.name === name) ?? list[0];
    }
}
