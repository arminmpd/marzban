#!/usr/bin/env bash
set -euo pipefail

cd /code

export HOST="0.0.0.0"
export PORT="${PORT:-8000}"
export UVICORN_HOST="$HOST"
export UVICORN_PORT="$PORT"
export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////code/data/db.sqlite3}"

echo "=========================================="
echo "🚀 Marzban Panel - Railway Deployment"
echo "=========================================="
echo "📅 Date: $(date)"
echo "🌐 Host: ${HOST}:${PORT}"
echo "📂 DB: ${SQLALCHEMY_DATABASE_URL}"
echo "=========================================="

mkdir -p /code/data /var/lib/marzban

echo "==> Running database migrations..."
alembic upgrade head || {
    echo "!! alembic failed; falling back to create_all()..."
    python - <<'PY'
import app.db.base as b
try:
    b.Base.metadata.create_all(bind=b.engine)
    print("✅ create_all() succeeded")
except Exception as e:
    print("❌ create_all() failed:", e)
PY
}

if [ -n "${SUDO_USERNAME:-}" ] && [ -n "${SUDO_PASSWORD:-}" ]; then
    echo "==> Creating sudo admin '${SUDO_USERNAME}'..."
    python create_admin.py --username "$SUDO_USERNAME" --password "$SUDO_PASSWORD" --sudo || true
fi

echo "==> Getting admin token..."
sleep 5

TOKEN=$(curl -s -X POST "http://localhost:${PORT}/api/admin/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${SUDO_USERNAME:-admin}&password=${SUDO_PASSWORD:-admin123}" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('access_token', ''))
except:
    print('')
" 2>/dev/null || echo "")

if [ -n "$TOKEN" ]; then
    echo "✅ Admin token: $TOKEN"
    echo "PANEL_API_TOKEN=$TOKEN" > /code/data/admin_token.txt
    echo "📝 Add this token as PANEL_API_TOKEN in Railway environment variables"
else
    echo "⚠️  Could not get admin token. Will retry after panel starts."
fi

echo "=========================================="
echo "✅ Marzban Panel is ready!"
echo "👤 Admin: ${SUDO_USERNAME:-admin}"
echo "🔑 Password: ${SUDO_PASSWORD:-admin123}"
echo "=========================================="

exec uvicorn main:app \
    --host "$HOST" \
    --port "$PORT" \
    --workers 1 \
    --proxy-headers \
    --forwarded-allow-ips '*' \
    --log-level info
