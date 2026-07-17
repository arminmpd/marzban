FROM python:3.12-slim

WORKDIR /app

# نصب وابستگی‌های سیستم
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# نصب Xray-core
RUN curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o /tmp/xray.zip \
    && apt-get install -y unzip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/xray \
    && rm /tmp/xray.zip

# کپی فایل‌های پروژه
COPY . .

# نصب وابستگی‌های Python
RUN pip install --no-cache-dir -r requirements.txt

# اجرای اسکریپت راه‌اندازی
CMD ["bash", "start.sh"]
