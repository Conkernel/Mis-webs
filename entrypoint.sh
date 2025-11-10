#!/bin/sh
set -e

echo "[INIT] Iniciando Node en background"
node /var/www/crawler/server.js &
NODE_PID=$!

echo "[INIT] Iniciando Nginx en foreground"
nginx -g "daemon off;" &
NGINX_PID=$!

# Esperar a que Node termine
wait $NODE_PID
NODE_EXIT=$?

echo "[INIT] Node terminó con código $NODE_EXIT, deteniendo Nginx..."
kill $NGINX_PID
wait $NGINX_PID

exit $NODE_EXIT
