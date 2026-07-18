#!/usr/bin/env bash
set -Eeuo pipefail

export UVICORN_HOST="${UVICORN_HOST:-0.0.0.0}"
export UVICORN_PORT="${PORT:-${UVICORN_PORT:-8000}}"
export XRAY_EXECUTABLE_PATH="${XRAY_EXECUTABLE_PATH:-/usr/local/bin/xray}"
export XRAY_ASSETS_PATH="${XRAY_ASSETS_PATH:-/usr/local/share/xray}"
export XRAY_JSON="${XRAY_JSON:-/var/lib/marzban/xray_config.json}"
export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/marzban/db.sqlite3}"

mkdir -p /var/lib/marzban

if [[ -n "${SUDO_USERNAME:-}" && -n "${SUDO_PASSWORD:-}" ]]; then
  echo "در حال بررسی مدیر اولیه..."
  # در نسخه‌های مختلف CLI ممکن است خروجی یا رفتار کمی متفاوت باشد.
  # شکست ساخت مدیر باعث توقف کل سرویس نمی‌شود.
  marzban-cli admin create \
    --sudo \
    --username "${SUDO_USERNAME}" \
    --password "${SUDO_PASSWORD}" >/dev/null 2>&1 || true
fi

echo "Marzban روی 0.0.0.0:${UVICORN_PORT} اجرا می‌شود."
exec python main.py
