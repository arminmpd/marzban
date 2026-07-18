#!/usr/bin/env bash

set -Eeuo pipefail

echo "========================================"
echo "Starting Marzban on Railway"
echo "========================================"

DATA_DIR="${MARZBAN_DATA_DIR:-/var/lib/marzban}"

mkdir -p "${DATA_DIR}"

export UVICORN_HOST="${UVICORN_HOST:-0.0.0.0}"
export UVICORN_PORT="${PORT:-${UVICORN_PORT:-8000}}"
export MARZBAN_DATA_DIR="${DATA_DIR}"

echo "Data directory: ${MARZBAN_DATA_DIR}"
echo "Listening on: ${UVICORN_HOST}:${UVICORN_PORT}"

cd /app

if command -v alembic >/dev/null 2>&1; then
    echo "Running database migrations..."
    alembic upgrade head
fi

echo "Starting Marzban application..."

exec python3 main.py
