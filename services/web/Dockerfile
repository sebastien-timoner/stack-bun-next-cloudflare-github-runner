FROM oven/bun:1.3.6

WORKDIR /app

# Installer les dépendances système nécessaires
RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Créer un utilisateur non-root
RUN useradd -m -s /bin/sh app && \
    mkdir -p /app && \
    chown -R app:app /app

# Configurer SSH
RUN mkdir -p /home/app/.ssh && \
    chmod 700 /home/app/.ssh && \
    chown -R app:app /home/app/.ssh

# Créer la structure des releases
RUN mkdir -p /app/releases && \
    chown -R app:app /app/releases

# Scripts de déploiement
COPY --chown=app:app entrypoint.sh /entrypoint.sh
COPY --chown=app:app deploy.sh /deploy.sh
RUN chmod +x /entrypoint.sh /deploy.sh

# Utiliser l'utilisateur non-root
USER app

ENTRYPOINT ["/entrypoint.sh"]
