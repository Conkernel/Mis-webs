#!/usr/bin/env bash

DISK="/dev/sda"

echo "=== Instalación automática Arch Linux ==="
echo "El siguiente disco será formateado: $DISK"
read -rp "¿Quieres continuar? (yes/no): " confirm < /dev/tty
# read -rp "¿Quieres continuar? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Abortado por el usuario"
    exit 1
fi

echo "Wipeando disco $DISK..."

# --- WIPE SEGURO DEL DISCO ---
sgdisk --zap-all "$DISK"
wipefs -a "$DISK"
dd if=/dev/zero of="$DISK" bs=1M count=10 status=progress

echo "Disco limpiado. Iniciando archinstall..."

# Ejecutar instalación sin menú

archinstall --config-url http://archy.web.casa.lan/user_configuration.json --silent #  --creds-url http://archy.web.casa.lan/creds.json 