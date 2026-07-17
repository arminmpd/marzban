#!/bin/bash

echo "=========================================="
echo "🚀 Starting Marzban Panel on Railway"
echo "=========================================="

export PORT=${PORT:-8000}
export HOST="0.0.0.0"

mkdir -p /app/data

cd /app

echo "✅ Starting FastAPI server..."
python -m uvicorn app:app --host 0.0.0.0 --port $PORT
