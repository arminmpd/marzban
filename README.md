# Marzban روی Railway بدون VPS

این بسته برای اجرای آزمایشی **Marzban Panel + Xray** در یک سرویس Railway ساخته شده است.

> محدودیت مهم: Railway پورت عمومی TCP را خودش تولید می‌کند. این راهکار برای شروع و کاربران کم مناسب است، نه سرویس پرترافیک یا فروش گسترده.

## فایل‌های مهم

- `Dockerfile`: ساخت Marzban و Xray
- `start-railway.sh`: اجرای سرویس با پورت خودکار Railway
- `railway.toml`: تنظیم Build و Health Check
- `.env.example`: نمونه متغیرهای محیطی
- `scripts/healthcheck.sh`: بررسی سلامت پنل

## مرحله ۱ — ساخت Repository در GitHub

1. در GitHub روی **New repository** بزنید.
2. نام را مثلاً `marzban-railway-starter` بگذارید.
3. Repository را Private یا Public بسازید.
4. تمام فایل‌های این پوشه را Upload کنید.
5. هیچ رمز واقعی را داخل `.env.example` قرار ندهید.

## مرحله ۲ — ساخت پروژه Railway

1. وارد Railway شوید.
2. `New Project` را بزنید.
3. `Deploy from GitHub Repo` را انتخاب کنید.
4. Repository خودتان را انتخاب کنید.
5. صبر کنید Build کامل شود.

## مرحله ۳ — افزودن Volume

در سرویس Marzban:

1. به `Settings` بروید.
2. بخش `Volumes` را باز کنید.
3. `Add Volume` را بزنید.
4. Mount Path را دقیقاً این مقدار قرار دهید:

```text
/var/lib/marzban
```

بدون Volume، دیتابیس SQLite بعد از Deploy مجدد ممکن است از بین برود.

## مرحله ۴ — تنظیم Variables

در `Variables` این مقادیر را اضافه کنید:

```env
TZ=Europe/Berlin
UVICORN_HOST=0.0.0.0
XRAY_EXECUTABLE_PATH=/usr/local/bin/xray
XRAY_ASSETS_PATH=/usr/local/share/xray
XRAY_JSON=/var/lib/marzban/xray_config.json
SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/marzban/db.sqlite3
SUDO_USERNAME=admin
SUDO_PASSWORD=یک_رمز_خیلی_طولانی_و_تصادفی
DASHBOARD_PATH=/dashboard/
DOCS=False
DEBUG=False
```

`PORT` را نسازید؛ Railway آن را خودکار تعیین می‌کند.

## مرحله ۵ — ساخت دامنه پنل

1. وارد `Settings > Networking` شوید.
2. در بخش Public Networking روی `Generate Domain` بزنید.
3. پنل را با این مسیر باز کنید:

```text
https://YOUR-DOMAIN.up.railway.app/dashboard/
```

بعد از اولین ورود، متغیر `SUDO_PASSWORD` را از Railway حذف کنید.

## مرحله ۶ — ساخت TCP Proxy برای Xray

1. در همان سرویس به `Settings > Networking` بروید.
2. بخش `TCP Proxy` را باز کنید.
3. Internal/Application Port را روی این مقدار بگذارید:

```text
10000
```

Railway یک آدرس مانند زیر می‌دهد:

```text
roundhouse.proxy.rlwy.net:15432
```

دامنه و پورت واقعی شما متفاوت خواهد بود.

## مرحله ۷ — ساخت Inbound داخل Marzban

در پنل Marzban وارد بخش Core Settings یا Xray Configuration شوید.

برای شروع، یک Inbound ساده بسازید که روی پورت داخلی `10000` گوش کند. نمونه پایه:

```json
{
  "tag": "VLESS_TCP_RAILWAY",
  "listen": "0.0.0.0",
  "port": 10000,
  "protocol": "vless",
  "settings": {
    "clients": [],
    "decryption": "none"
  },
  "streamSettings": {
    "network": "tcp",
    "security": "none"
  },
  "sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls"]
  }
}
```

سپس Host Settings را با اطلاعات TCP Proxy تنظیم کنید:

```text
Address: دامنه TCP Proxy که Railway داده است
Port: پورت خارجی TCP Proxy
SNI: خالی
TLS: خاموش
Transport: TCP
```

پورت داخل Inbound همیشه `10000` است؛ ولی پورت داخل کانفیگ کاربر باید **پورت خارجی Railway** باشد.

## مرحله ۸ — ساخت کاربر

1. در پنل یک User جدید بسازید.
2. پروتکل VLESS را فعال کنید.
3. لینک ساخته‌شده را بررسی کنید.
4. Host و Port باید با TCP Proxy Railway یکی باشند.
5. ابتدا با یک کاربر آزمایشی تست کنید.

## رفع خطا

### پنل باز نمی‌شود

- Deploy Logs را بررسی کنید.
- مطمئن شوید دامنه عمومی ساخته شده است.
- `PORT` را دستی تنظیم نکنید.
- Health Check باید `/` باشد.

### بعد از Deploy کاربران حذف شدند

Volume روی مسیر زیر متصل نشده است:

```text
/var/lib/marzban
```

### کانفیگ وصل نمی‌شود

- TCP Proxy باید روی پورت داخلی `10000` باشد.
- Inbound باید روی `0.0.0.0:10000` گوش کند.
- در لینک کاربر از پورت خارجی Railway استفاده شود.
- پروتکل UDP روی این معماری در نظر گرفته نشده است.

### ساخت مدیر انجام نشد

از Railway Shell یا Console این دستور را اجرا کنید:

```bash
marzban-cli admin create --sudo
```

## به‌روزرسانی

در حال حاضر Build از شاخه `master` Marzban استفاده می‌کند. برای پایداری بیشتر، بعداً `MARZBAN_REF` را روی Tag یا Commit مشخص قرار دهید.

## هشدار

از این پروژه فقط مطابق قوانین محل زندگی و شرایط استفاده Railway استفاده کنید. برای سرویس پایدار، ترافیک بالا، Reality، چند پورت یا UDP، بعداً Xray را به VPS منتقل کنید.
