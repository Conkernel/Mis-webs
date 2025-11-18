#!/bin/bash
set -e

# ============ COLORES ============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
NC="\033[0m" # Sin color


#
# $SUDO_USER está definida solo si el script fue llamado usando 'sudo'.
# Esta variable contiene el nombre del usuario original que invocó 'sudo'.
#
if [ -n "$SUDO_USER" ]; then
  # El argumento '-n' evalúa si la cadena de texto NO es nula (está definida).
  
  echo "------------------------------------------------------------"
  echo -e "${RED} ERROR: Detectado el uso de 'sudo'.${NC}"
  echo "------------------------------------------------------------"
  echo
  echo "Este script instala la configuración en el directorio personal ($HOME)."
  echo "Si lo ejecutas con 'sudo', la configuración se instalará en el Home de root."
  echo "Por favor, ejecuta el script SIN usar 'sudo', pero con un usuario con permisos"
  echo
  
  # Sale del script con un código de error
  exit 1
fi

error() { echo -e "${RED}ERROR: $1${NC}" >&2; exit 1; }

# ============ 1. DETECTAR DISTRO ============
echo -e "${BLUE}Verificando sistema...${NC}"
[ -f /etc/os-release ] && . /etc/os-release || error "No se encontró /etc/os-release"
[[ "$ID" =~ ^(ubuntu|debian)$ ]] || error "Solo Ubuntu/Debian. Detectado: $ID"
echo -e "${GREEN}Compatible: $PRETTY_NAME${NC}"

# ============ AVISO ============

echo "Antes de nada, este script ELIMINARÁ cualquier instalación previa de Nvim a través de apt"
echo "Luego instalará la AppImage de la última versión estable de Neovim Appimage en Ubuntu."
echo "Instalará libfuse2 (necesario para AppImages en Ubuntu 22+), descargará el archivo y lo colocará en /usr/local/bin/nvim."
echo "¿Realmente quieres proceder con la instalación? (y/n)"


# Forzar interacción si no hay TTY (curl | sudo bash)
if [ -t 0 ]; then
    read -r
else
    echo -e "${YELLOW}ADVERTENCIA: Ejecución no interactiva detectada (curl | sudo bash)${NC}"
    echo -e "${YELLOW}¿Deseas continuar? (y/n):${NC}"
    read -r CONFIRM < /dev/tty
    [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo -e "${RED}Instalación cancelada por el usuario.${NC}"; exit 1; }
fi

# ============ SUDO ============
SUDO() { [[ $EUID -eq 0 ]] && "$@" || sudo "$@"; }

# ============ 4. DEPENDENCIAS ============
echo -e "${YELLOW}Instalando dependencias...${NC}"


# Desinstalar cualquier versión de Neovim instalada vía apt
echo "Desinstalando cualquier versión de Neovim instalada vía apt..."
sudo apt remove --purge -y neovim
sudo apt autoremove -y

SUDO apt update
SUDO apt install -y git curl wget fuse3 libfuse2 build-essential ca-certificates


# Descarga la AppImage
echo "Descargando la AppImage..."
curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage

# Hazlo ejecutable
chmod +x nvim-linux-x86_64.appimage

# Muévelo a /usr/local/bin/nvim (requiere sudo)
echo "Moviendo a /usr/local/bin/nvim..."
sudo mv nvim-linux-x86_64.appimage /usr/local/bin/nvim


# ============ CONFIGURAR LAZYVIM + AYU ============
CONFIG="$HOME/.config/nvim"

# Backup si existe
if [ -d "$CONFIG" ]; then
    BACKUP_DIR="$CONFIG.backup.$(date +%s)"
    mv "$CONFIG" "$BACKUP_DIR"
    echo -e "${YELLOW}Backup creado: $BACKUP_DIR${NC}"
fi

echo -e "${YELLOW}Instalando LazyVim...${NC}"
git clone --depth 1 https://github.com/LazyVim/starter "$CONFIG"



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



# Crear o modificar options.lua con la configuración del ratón y clipboard
OPTIONS_FILE=~/.config/nvim/lua/config/options.lua
if [ ! -f "$OPTIONS_FILE" ]; then
    mkdir -p $(dirname "$OPTIONS_FILE")
    touch "$OPTIONS_FILE"
fi

echo "" >> "$OPTIONS_FILE"
echo "-- Enable mouse support" >> "$OPTIONS_FILE"
echo 'vim.opt.mouse = "a"' >> "$OPTIONS_FILE"
echo "-- Use system clipboard" >> "$OPTIONS_FILE"
echo 'vim.g.clipboard = "osc52"' >> "$OPTIONS_FILE"


cp ~/.config/nvim/init.lua /tmp//init.lua.tmp
echo "" > ~/.config/nvim/init.lua

# Keymap is "space"
LUA_FILE=~/.config/nvim/init.lua
if [ ! -f "$LUA_FILE" ]; then
    mkdir -p $(dirname "$LUA_FILE")
    touch "$LUA_FILE"
fi
echo "" >> "$LUA_FILE"
echo '-- Leader key is "space":' >> "$LUA_FILE"
echo 'vim.g.mapleader = " "' >> "$LUA_FILE"
echo 'vim.g.maplocalleader = " "' >> "$LUA_FILE"

cat /tmp//init.lua.tmp >> ~/.config/nvim/init.lua
rm -fr /tmp//init.lua.tmp






# ============ FINAL ============
echo -e "${BLUE}========================================================${NC}"
echo -e "${GREEN}¡INSTALACIÓN COMPLETA!${NC}"
echo -e "   • Neovim: $NVIM_VER"
echo -e "   • mouse + unnamed plus"
echo -e "   • LazyVim + Ayu + tree-sitter automático"
echo -e "   • Primera vez: espera 10-30s para instalar plugins"
echo -e "${BLUE}========================================================${NC}"

