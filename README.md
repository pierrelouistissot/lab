# Dockerfile

On prend l'image officiel ubuntu:22.04
On installe : -sudo:permet a l'utilisateur d'éxécuter des commandes dans l'environnement
-cron: outil de planification(tache automatique)
-nano editeur de texte

On creer un utilisateur player
`useradd` : ajoute un compte user
`-m` : crée aussi le repertoire /home/player

On creer le password du player avec `RUN echo "player:player123" | chpasswd`
chpasswd lit le echo et met a jour /etc/shadow

`RUN echo "player ALL=(root) NOPASSWD: /usr/bin/find" >> /etc/sudoers`
Elle ajoute une règle dans le fichier /etc/sudoers (le fichier qui dit qui peut faire quoi en sudo).

player : l’utilisateur concerné

ALL= : depuis n’importe quel hôte (dans un vrai système multi-host)

(root) : il peut exécuter en tant que root

NOPASSWD: : sans demander le mot de passe

/usr/bin/find : uniquement cette commande

