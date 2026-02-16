FROM ubuntu:22.04

RUN apt update && apt install -y sudo cron nano

RUN useradd -m player
RUN echo "player:player123" | chpasswd

# vuln sudo
RUN echo "player ALL=(root) NOPASSWD: /usr/bin/find" >> /etc/sudoers

WORKDIR /home/player
USER player

CMD ["/bin/bash"]
