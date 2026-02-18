FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    iputils-ping \
    dnsutils \
    netcat-openbsd \
    nmap \
    curl \
    wget \
    openssh-client \
    python3 \
    nano \
    vim \
    net-tools \
    iproute2 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["sleep", "infinity"]