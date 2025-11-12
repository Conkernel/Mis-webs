#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${YELLOW}   Instalando Neovim (última versión) + LazyVim + Ayu Theme${NC}"
echo -e "${BLUE}============================================================${NC}"

# 1. Añadir PPA oficial de Neovim (unstable = última versión)
echo -e "${YELLOW}Añadiendo PPA: neovim-ppa/unstable...${NC}"
if ! grep -q "neovim-ppa/unstable" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
  sudo add-apt-repository -y ppa:neovim-ppa/unstable
  echo -e "${GREEN}PPA añadido.${NC}"
else
  echo -e "${GREEN}PPA ya estaba añadido.${NC}"
fi

# 2. Actualizar paquetes e instalar Neovim (última versión)
echo -e "${YELLOW}Actualizando repositorios e instalando Neovim...${NC}"
sudo apt update
sudo apt install -y neovim

# Verificar versión
NVIM_VERSION=$(nvim --version | head -n1)tree-sitter --version
echo -e "${GREEN}Neovim instalado: $NVIM_VERSION${NC}"

# 3. Respaldar configuración antigua (si existe)
CONFIG_DIR="$HOME/.config/nvim"
BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%s)"

if [ -d "$CONFIG_DIR" ] && [ ! -L "$CONFIG_DIR" ]; then
  echo -e "${YELLOW}Respaldando configuración actual en $BACKUP_DIR${NC}"
  mv "$CONFIG_DIR" "$BACKUP_DIR"
fi

# 4. Instalar LazyVim (starter oficial)
echo -e "${YELLOW}Instalando LazyVim (distribución completa)...${NC}"
git clone https://github.com/LazyVim/starter "$CONFIG_DIR"
rm -rf "$CONFIG_DIR/.git"

# 5. Añadir el tema Ayu
AYU_FILE="$CONFIG_DIR/lua/plugins/ayu.lua"

mkdir -p "$CONFIG_DIR/lua/plugins"

cat >"$AYU_FILE" <<'EOF'
return {
  {
    "Shatur/neovim-ayu",
    lazy = false,
    priority = 1000,
    config = function()
      require("ayu").setup({
        mirage = true,  -- true = oscuro suave, false = claro
        overrides = {},
      })
      vim.cmd("colorscheme ayu")
    end,
  },
}
EOF

echo -e "${GREEN}Tema Ayu configurado en $AYU_FILE${NC}"

# 6. Mensaje final y lanzamiento
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}¡Todo listo!${NC}"
echo -e "${YELLOW}Se ha instalado:"
echo -e "   • Neovim ${NVIM_VERSION}"
echo -e "   • LazyVim (con dashboard)"
echo -e "   • Tema Ayu (mirage = oscuro)"
echo -e ""
echo -e "${YELLOW}Iniciando Neovim... (primera vez tardará en instalar plugins)${NC}"
echo -e "${BLUE}============================================================${NC}"

# Lanzar Neovim
exec nvim

