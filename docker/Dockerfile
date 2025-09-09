# Multi-stage build pour optimisation
FROM python:3.11-slim as builder

WORKDIR /app

# Copier les requirements
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage final
FROM python:3.11-slim

# Labels pour GHCR
LABEL org.opencontainers.image.source=https://github.com/xclem/poc-openhands
LABEL org.opencontainers.image.description="POC OpenHands - Prompt to Production Pipeline"
LABEL org.opencontainers.image.licenses=MIT

WORKDIR /app

# Copier les dépendances depuis le builder
COPY --from=builder /root/.local /root/.local

# Copier le code de l'application
COPY src/ ./src/

# Variables d'environnement
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Port d'exposition
EXPOSE 8000

# Commande de démarrage
CMD ["python", "-m", "uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
