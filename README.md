# tbe-dots-files — branche serpantinum

Bureau Hyprland sous [serpantinum](https://github.com/ilyamiro/serpantinum).

Serpantinum s'installe et se met a jour tout seul ; ce depot ne duplique donc
pas sa configuration. Il ne garde que ce que son installateur ecrase a chaque
passage, plus les fichiers qui n'appartiennent qu'a cette machine.

| Fichier | Role |
|---|---|
| `post-install.sh` | Rejoue les corrections de raccourcis apres chaque install ou mise a jour de serpantinum |
| `certs/` | Certificats de CA interne que le systeme doit approuver |

## post-install.sh

```sh
./post-install.sh
```

Idempotent : il detecte ce qui est deja en place et ne touche a rien d'autre.
Il sauvegarde `keybinds.lua` avant sa premiere modification, et s'arrete net si
un motif a disparu plutot que de patcher a moitie.

Ce qu'il corrige :

- **La disposition clavier repasse en francais**, dans `config/settings.lua`.
  L'installateur la remet a `us` a chaque passage. Le `us` est garde en second
  groupe, `Alt+Shift` bascule entre les deux.

Et dans `config/keybinds.lua` :

- **`SUPER+T`** ouvre le terminal, en plus de `SUPER+Return`
- **`SUPER+A`** ouvre le lanceur ; l'autohide qui occupait cette touche passe
  sur `SUPER+SHIFT+A`
- **Les workspaces repondent aux touches `& e " ' (`**. Serpantinum bind les
  keysyms `1`..`0`, or en AZERTY les chiffres sont sur le niveau Shift : ces
  raccourcis etaient injouables. On passe par les codes bruts `10..19`, qui
  designent la rangee physique quelle que soit la disposition.

## L'ancienne configuration

La branche `master` contient la configuration end-4 (illogical-impulse) qui
faisait tourner cette machine avant serpantinum, avec tout son historique.
Rien n'en a ete supprime.
