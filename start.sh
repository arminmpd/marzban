#!/bin/bash

echo "=========================================="
echo "🚀 Starting Marzban Panel on Railway"
echo "=========================================="

# تنظیم پورت
export PORT=${PORT:-8000}
export HOST="0.0.0.0"

# ایجاد دایرکتوری‌ها
mkdir -p /app/data

# اجرای پنل
cd /app
python -c "
import os
os.chdir('/app')
exec(open('app.py').read())
" &

# نمایش لاگ‌ها
echo "✅ Panel started on port $PORT"
echo "🌐 URL: https://$RAILWAY_STATIC_URL"
echo "=========================================="

# نگه داشتن کانتینر
tail -f /dev/null
