FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo python3 python3-minimal ca-certificates \
    procps psmisc net-tools iproute2 iputils-ping \
    nano vim less curl wget \
    openssh-server openssh-client \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash player \
 && useradd -m -s /bin/bash ops

RUN echo "player:player123" | chpasswd \
 && echo "ops:v3ryStr0ngOpsP@ss!" | chpasswd

RUN echo "FLAG{user_recon_first}" > /home/player/user.txt \
 && chown player:player /home/player/user.txt \
 && chmod 640 /home/player/user.txt

RUN echo "FLAG{root_owned_backup_chain}" > /root/root.txt \
 && chmod 600 /root/root.txt

RUN mkdir -p /opt/app /var/log/app \
 && echo "[INFO] App started successfully" > /var/log/app/app.log \
 && echo "[WARN] Temporary maintenance: rotated ops credentials stored for admin convenience" >> /var/log/app/app.log \
 && echo "[WARN] File: /opt/app/.passwd (TODO: remove before production)" >> /var/log/app/app.log

RUN printf "b3BzOnYzcnlTdHIwbmdPcHNQQHNzIQ==\n" > /opt/app/.passwd \
 && chmod 644 /opt/app/.passwd

RUN echo "db_password=not_the_real_one" > /opt/app/.env \
 && chmod 644 /opt/app/.env

RUN mkdir -p /var/backup/run /opt/backup \
 && chown ops:ops /var/backup/run \
 && chmod 775 /var/backup/run

RUN echo "ops ALL=(root) NOPASSWD: /usr/local/bin/backup.sh" > /etc/sudoers.d/ops-backup \
 && chmod 440 /etc/sudoers.d/ops-backup

COPY privesc-advanced/files/backup.sh /usr/local/bin/backup.sh
COPY privesc-advanced/files/backup.py /opt/backup/backup.py
COPY privesc-advanced/files/utils.py  /opt/backup/utils.py

RUN chmod 755 /usr/local/bin/backup.sh /opt/backup/backup.py \
 && chown root:root /usr/local/bin/backup.sh /opt/backup/backup.py /opt/backup/utils.py \
 && chmod 644 /opt/backup/utils.py

WORKDIR /home/player

# Clé SSH stockée côté root sur M1 (pour se connecter à M2)
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh
COPY privesc-advanced/files/m1_id_ed25519 /root/.ssh/id_ed25519
COPY privesc-advanced/files/m1_id_ed25519.pub /root/.ssh/id_ed25519.pub
RUN chmod 600 /root/.ssh/id_ed25519

COPY privesc-advanced/files/entrypoint-m1.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 22
CMD ["/entrypoint.sh"]