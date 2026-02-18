#!/bin/bash
# Démarrer le service SSH
mkdir -p /var/run/sshd
ssh-keygen -A                        # génère les clés hôte si absentes
/usr/sbin/sshd                       # démarre le daemon SSH en arrière-plan

# Garder le container vivant en tant que player
exec su - player -c "sleep infinity"