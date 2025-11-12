#!/bin/bash
set -e

USERHOME=

# ============ COLORES ============
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
error() { echo -e "${RED}ERROR: $1${NC}" >&2; exit 1; }

# ============ 1. DETECTAR DISTRO ============
echo -e "${BLUE}Verificando sistema...${NC}"
[ -f /etc/os-release ] && . /etc/os-release || error "No se encontró /etc/os-release"
[[ "$ID" =~ ^(ubuntu|debian)$ ]] || error "Solo Ubuntu/Debian. Detectado: $ID"
echo -e "${GREEN}Compatible: $PRETTY_NAME${NC}"

# ============ 2. AVISO ============
cat << 'EOF'

============================================================
               INSTALADOR NEOVIM + LAZYVIM
============================================================

→ Neovim AppImage (última versión estable)
→ LazyVim + tema Ayu (oscuro - mirage)
→ tree-sitter: se instala automáticamente
→ Backup de ~/.config/nvim

Presiona ENTER para continuar (o Ctrl+C para salir)...
EOF

# Forzar interacción si no hay TTY (curl | sudo bash)
if [ -t 0 ]; then
    read -r
else
    echo -e "${YELLOW}ADVERTENCIA: Ejecución no interactiva detectada (curl | sudo bash)${NC}"
    echo -e "${YELLOW}¿Deseas continuar? (y/n):${NC}"
    read -r CONFIRM < /dev/tty
    [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo -e "${RED}Instalación cancelada por el usuario.${NC}"; exit 1; }
fi

# ============ 3. SUDO ============
SUDO() { [[ $EUID -eq 0 ]] && "$@" || sudo "$@"; }

# ============ 4. DEPENDENCIAS ============
echo -e "${YELLOW}Instalando dependencias...${NC}"
SUDO apt update
SUDO apt install -y git curl wget fuse3 libfuse2 build-essential ca-certificates

# ============ 5. DETECTAR Y DESCARGAR NEOVIM APPIMAGE ============
echo -e "${YELLOW}Detectando versión más reciente de Neovim...${NC}"
LATEST_URL=$(curl -fsL -o /dev/null -w "%{url_effective}" https://github.com/neovim/neovim/releases/latest)
NVIM_VERSION=$(echo "$LATEST_URL" | sed 's|.*/tag/v||' | sed 's|/.*||')
[ -z "$NVIM_VERSION" ] && error "No se pudo detectar versión"

APPIMAGE_URL="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.appimage"
# APP="$HOME/nvim.appimage"
APP="/usr/local/bin/nvim"

echo -e "${YELLOW}Descargando Neovim v${NVIM_VERSION}...${NC}"
SUDO curl -fLo "$APP" \
  --retry 3 \
  --retry-delay 5 \
  -H "User-Agent: curl/neovim-installer" \
  "$APPIMAGE_URL"

# Verificar que sea ejecutable
SUDO file "$APP" | grep -q "ELF 64-bit" || error "AppImage corrupto o no descargado"
SUDO chmod +x "$APP"

NVIM_VER=$("$APP" --version | head -n1)
echo -e "${GREEN}Neovim instalado: $NVIM_VER${NC}"

# ============ 6. EVITAR CONFLICTO CON NEOVIM DE APT ============
if command -v nvim >/dev/null 2>&1; then
    OLD_NVIM=$(realpath $(which nvim))
    if [[ "$OLD_NVIM" != "$APP" && "$OLD_NVIM" != "/usr/local/bin/nvim" ]]; then
        echo -e "${YELLOW}Neovim de apt detectado → moviendo a nvim.apt${NC}"
        SUDO mv "$OLD_NVIM" "${OLD_NVIM}.apt" 2>/dev/null || true
    fi
fi
# SUDO ln -sf "$APP" /usr/local/bin/nvim

# ============ 7. CONFIGURAR LAZYVIM + AYU ============
CONFIG="$HOME/.config/nvim"

# Backup si existe
if [ -d "$CONFIG" ]; then
    BACKUP_DIR="$CONFIG.backup.$(date +%s)"
    mv "$CONFIG" "$BACKUP_DIR"
    echo -e "${YELLOW}Backup creado: $BACKUP_DIR${NC}"
fi

echo -e "${YELLOW}Instalando LazyVim...${NC}"
git clone --depth 1 https://github.com/LazyVim/starter "$CONFIG"

echo -e "${YELLOW}Borrando rastros de .git... ${NC}"

rm $CONFIG/.git -rf

# Crear directorio de plugins
mkdir -p "$CONFIG/lua/plugins"

# Añadir tema Ayu
cat > "$CONFIG/lua/plugins/ayu.lua" << 'EOF'
return {
  {
    "Shatur/neovim-ayu",
    lazy = false,
    priority = 1000,
    config = function()
      require("ayu").setup({ mirage = true })
      vim.cmd("colorscheme ayu")
    end,
  },
}
EOF

echo -e "${GREEN}Tema Ayu (mirage) configurado${NC}"
echo -e "${YELLOW}tree-sitter se instalará automáticamente al abrir archivos${NC}"

# ============ 8. FINAL ============
echo -e "${BLUE}========================================================${NC}"
echo -e "${GREEN}¡INSTALACIÓN COMPLETA!${NC}"
echo -e "   • Neovim: $NVIM_VER"
echo -e "   • LazyVim + Ayu + tree-sitter automático"
echo -e "   • Primera vez: espera 10-30s para instalar plugins"
echo -e "${BLUE}========================================================${NC}"

# ============ 9. LANZAR NEOVIM ============
# Al final del script
if [[ $EUID -eq 0 ]]; then
    exec sudo -u "$SUDO_USER" "$APP"   # ← Neovim se abre como oloco
else
    exec "$APP"
fi