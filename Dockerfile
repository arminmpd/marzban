FROM gozargah/marzban:latest

USER root

COPY entrypoint.sh /entrypoint-railway.sh

RUN chmod +x /entrypoint-railway.sh \
    && mkdir -p /var/lib/marzban

ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8000
ENV RAILWAY_RUN_UID=0

EXPOSE 8000

ENTRYPOINT ["/entrypoint-railway.sh"]
