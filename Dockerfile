# syntax=docker/dockerfile:1.7

ARG PYTHON_VERSION=3.12

# -----------------------------
# Stage 1: Build Marzban
# -----------------------------
FROM python:${PYTHON_VERSION}-slim-bookworm AS builder

ARG MARZBAN_REPO=https://github.com/Gozargah/Marzban.git
ARG MARZBAN_REF=master

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    for i in 1 2 3; do \
      apt-get update && break || sleep 5; \
    done; \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      git \
      gcc \
      libffi-dev \
      libssl-dev \
      unzip; \
    rm -rf /var/lib/apt/lists/*

# Node.js 20 برای ساخت Dashboard
RUN set -eux; \
    curl -fsSL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource.sh; \
    bash /tmp/nodesource.sh; \
    apt-get update; \
    apt-get install -y --no-install-recommends nodejs; \
    rm -f /tmp/nodesource.sh; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone --depth 1 --branch "${MARZBAN_REF}" "${MARZBAN_REPO}" .

# محیط مجازی ثابت؛ دیگر به مسیر python3.12/site-packages وابسته نیست
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt

# ساخت داشبورد فقط در صورت وجود پوشه و package.json
RUN set -eux; \
    if [ -f app/dashboard/package.json ]; then \
      cd app/dashboard; \
      if [ -f package-lock.json ]; then \
        npm ci --no-audit --no-fund; \
      else \
        npm install --no-audit --no-fund; \
      fi; \
      npm run build --if-present -- --outDir build --assetsDir statics; \
      if [ -f build/index.html ]; then cp build/index.html build/404.html; fi; \
    fi

# نصب Xray با اسکریپت رسمی مورد استفاده اکوسیستم Marzban
RUN set -eux; \
    curl -fsSL \
      https://raw.githubusercontent.com/Gozargah/Marzban-scripts/master/install_latest_xray.sh \
      -o /tmp/install-xray.sh; \
    bash /tmp/install-xray.sh; \
    rm -f /tmp/install-xray.sh

# -----------------------------
# Stage 2: Runtime
# -----------------------------
FROM python:${PYTHON_VERSION}-slim-bookworm AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PATH="/opt/venv/bin:${PATH}" \
    UVICORN_HOST=0.0.0.0 \
    XRAY_EXECUTABLE_PATH=/usr/local/bin/xray \
    XRAY_ASSETS_PATH=/usr/local/share/xray \
    XRAY_JSON=/var/lib/marzban/xray_config.json \
    SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/marzban/db.sqlite3

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# retry باعث می‌شود خطاهای موقت apt روی Railway کمتر Build را خراب کنند
RUN set -eux; \
    for i in 1 2 3; do \
      apt-get update && break || sleep 5; \
    done; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tini \
      tzdata; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /code

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /build /code
COPY --from=builder /usr/local/bin/xray /usr/local/bin/xray
COPY --from=builder /usr/local/share/xray /usr/local/share/xray

RUN set -eux; \
    mkdir -p /var/lib/marzban; \
    useradd --create-home --uid 1000 --shell /usr/sbin/nologin marzban; \
    chown -R marzban:marzban /code /var/lib/marzban

USER marzban

EXPOSE 8000 10000

HEALTHCHECK --interval=30s --timeout=8s --start-period=90s --retries=5 \
  CMD sh -c 'curl -fsS "http://127.0.0.1:${PORT:-8000}/" >/dev/null || exit 1'

ENTRYPOINT ["/usr/bin/tini", "--"]

# Railway متغیر PORT را خودکار قرار می‌دهد
CMD ["/opt/venv/bin/python", "main.py"]
