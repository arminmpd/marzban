#!/usr/bin/env bash
set -euo pipefail

cd /code

echo "=========================================="
echo "🚀 Marzban Node - Railway Deployment"
echo "=========================================="
echo "🔧 SERVICE_PORT: ${SERVICE_PORT:-62050}"
echo "🔧 XRAY_API_PORT: ${XRAY_API_PORT:-62051}"
echo "=========================================="

mkdir -p "${SSL_DIR:-/var/lib/marzban-node}"

if [ -n "${SSL_CLIENT_CERT:-}" ]; then
    export SSL_CLIENT_CERT_FILE="${SSL_CLIENT_CERT_FILE:-/var/lib/marzban-node/ssl_client_cert.pem}"
    echo "🔒 Writing SSL certificate..."
    printf '%s\n' "${SSL_CLIENT_CERT}" > "${SSL_CLIENT_CERT_FILE}"
else
    unset SSL_CLIENT_CERT_FILE || true
    echo "⚠️  SSL_CLIENT_CERT not set - starting without client certificate"
fi

echo "==> Starting Marzban-node..."
exec python main.py
