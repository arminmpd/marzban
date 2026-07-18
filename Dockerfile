# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim AS builder

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc python3-dev libpq-dev git curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

ARG MARZBAN_REPO=https://github.com/Gozargah/Marzban.git
ARG MARZBAN_REF=master
RUN git clone --depth 1 --branch "${MARZBAN_REF}" "${MARZBAN_REPO}" .

# نصب Xray با اسکریپت رسمی مورد استفاده پروژه مرجع
RUN curl -fsSL \
    https://github.com/Gozargah/Marzban-scripts/raw/master/install_latest_xray.sh \
    | bash

RUN cd app/dashboard \
    && if [ -f package-lock.json ]; then npm ci --no-audit --no-fund; \
       else npm install --no-audit --no-fund; fi \
    && VITE_BASE_API=/api/ npm run build --if-present -- \
       --outDir build --assetsDir statics \
    && cp build/index.html build/404.html \
    && cd ../..

RUN python -m pip install --upgrade pip wheel \
    && pip install "setuptools==75.8.0" \
    && pip install -r requirements.txt

FROM python:${PYTHON_VERSION}-slim AS runtime

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    XRAY_EXECUTABLE_PATH=/usr/local/bin/xray \
    XRAY_ASSETS_PATH=/usr/local/share/xray \
    XRAY_JSON=/var/lib/marzban/xray_config.json \
    SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/marzban/db.sqlite3 \
    UVICORN_HOST=0.0.0.0 \
    TZ=UTC

WORKDIR /code

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tini \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.12/site-packages \
    /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/share/xray /usr/local/share/xray
COPY --from=builder /build /code

COPY start-railway.sh /code/start-railway.sh
COPY scripts/healthcheck.sh /usr/local/bin/healthcheck

RUN chmod +x /code/start-railway.sh /usr/local/bin/healthcheck \
    && ln -sf /code/marzban-cli.py /usr/local/bin/marzban-cli \
    && mkdir -p /var/lib/marzban \
    && useradd --create-home --uid 1000 appuser \
    && chown -R appuser:appuser /code /var/lib/marzban

USER appuser

EXPOSE 8000 10000

HEALTHCHECK --interval=30s --timeout=8s --start-period=60s --retries=5 \
    CMD ["healthcheck"]

ENTRYPOINT ["/usr/bin/tini", "--", "/code/start-railway.sh"]
