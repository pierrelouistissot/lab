FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server cron sudo ca-certificates \
    procps iproute2 iputils-ping nano \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd

# User initial sur M2
RUN useradd -m -s /bin/bash dev \
 && echo "dev:dev123" | chpasswd

# Flags
RUN echo "FLAG{m2_user}" > /home/dev/user.txt \
 && chown dev:dev /home/dev/user.txt \
 && chmod 640 /home/dev/user.txt

RUN echo "FLAG{m2_root}" > /root/root.txt \
 && chmod 600 /root/root.txt

# Autoriser la clé de M1 à se connecter en SSH sur dev
RUN mkdir -p /home/dev/.ssh \
 && chmod 700 /home/dev/.ssh \
 && chown -R dev:dev /home/dev/.ssh

# On copie la clé publique depuis TON repo (machine2 build context)
COPY files/m1_id_ed25519.pub /home/dev/.ssh/authorized_keys
RUN chown dev:dev /home/dev/.ssh/authorized_keys \
 && chmod 600 /home/dev/.ssh/authorized_keys

# Privesc sur M2 : cron root exécute un script modifiable par dev (volontairement)
RUN mkdir -p /opt/maint \
 && chown dev:dev /opt/maint \
 && chmod 775 /opt/maint

COPY files/root_cron.sh /opt/maint/root_cron.sh
RUN chown dev:dev /opt/maint/root_cron.sh \
 && chmod 775 /opt/maint/root_cron.sh

RUN printf '* * * * * root /opt/maint/root_cron.sh >/dev/null 2>&1\n' > /etc/cron.d/maint \
 && chmod 644 /etc/cron.d/maint

COPY files/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 22
CMD ["/entrypoint.sh"]
