# Conventions de travail

## Commits

Pas de `Co-Authored-By`, pas de mention « Generated with Claude Code » dans les
commits ni dans les descriptions de merge request. L'historique du dépôt ne
porte que mon nom.

Ne jamais commiter ni merger à ma place. Je gère mes commits moi-même, sauf si
je le demande explicitement.

Quand je le demande, le message suit la convention semantic-release : un type
parmi `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `perf:`, `test:`,
`build:`, `ci:`, suivi du sujet. Un `!` après le type, ou un bloc
`BREAKING CHANGE:` en pied de message, pour une rupture de compatibilité.

## Commentaires

Une ligne courte, dans la langue et le style du fichier modifié. Pas de bloc
explicatif de plusieurs lignes au-dessus d'une variable, pas de paragraphe
justifiant un choix technique. Si l'explication ne tient pas sur une ligne, sa
place est dans le message de commit, pas dans le fichier.

La même retenue vaut pour le corps des messages de commit.
