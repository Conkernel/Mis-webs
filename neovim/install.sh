#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
error() { echo -e "${RED}ERROR: $1${NC}" >&2; exit 1; }

# 1. Detectar distro
[ -f /etc/os-release ] && . /etc/os-release || error "No /etc/os-release"
[[ "$ID" =~ ^(ubuntu|debian)$ ]] || error "Solo Ubuntu/Debian. Detectado: $ID"

# 2. Aviso
cat << 'EOF'

============================================================
               INSTALADOR NEOVIM + LAZYVIM
============================================================

→ Neovim AppImage (última versión)
→ LazyVim + Ayu + tree-sitter
→ Backup de config

Presiona ENTER para continuar...
EOF
read -r

# 3. Sudo
SUDO() { [[ $EUID -eq 0 ]] && "$@" || sudo "$@"; }

# 4. Dependencias
echo -e "${YELLOW}Instalando dependencias...${NC}"
SUDO apt update
SUDO apt install -y git curl wget fuse3 libfuse2 build-essential ca-certificates

# 5. Detectar versión con SED (compatible con Debian)
echo -e "${YELLOW}Detectando versión más reciente de Neovim...${NC}"
LATEST_URL=$(curl -fsL -o /dev/null -w "%{url_effective}" https://github.com/neovim/neovim/releases/latest)
NVIM_VERSION=$(echo "$LATEST_URL" | sed 's|.*/tag/v||' | sed 's|/.*||')
[ -z "$NVIM_VERSION" ] && error "No se pudo detectar versión"

APPIMAGE_URL="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.appimage"
APP="$HOME/nvim.appimage"

echo -e "${YELLOW}Descargando Neovim v${NVIM_VERSION}...${NC}"
curl -fLo "$APP" \
  --retry 3 \
  --retry-delay 5 \
  -H "User-Agent: curl/neovim-installer" \
  "$APPIMAGE_URL"

# Verificar AppImage
file "$APP" | grep -q "ELF 64-bit" || error "AppImage no válido"
chmod +x "$APP"

NVIM_VER=$("$APP" --version | head -n1)
echo -e "${GREEN}Neovim: $NVIM_VER${NC}"

# 6. Evitar conflicto con nvim de apt
if command -v nvim >/dev/null 2>&1; then
    OLD_NVIM=$(realpath $(which nvim))
    if [[ "$OLD_NVIM" != "$APP" && "$OLD_NVIM" != "/usr/local/bin/nvim" ]]; then
        echo -e "${YELLOW}Neovim apt detectado → renombrando a nvim.apt${NC}"
        SUDO mv "$OLD_NVIM" "${OLD_NVIM}.apt" 2>/dev/null || true
    fi
fi
SUDO ln -sf "$APP" /usr/local/bin/nvim

# 7. tree-sitter
# echo -e "${YELLOW}Instalando tree-sitter CLI...${NC}"
# if ! command -v tree-sitter &>/dev/null; then
#     if ! command -v cargo &>/dev/null; then
#         echo "Instalando Rust..."
#         curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
#         source "$HOME/.cargo/env"
#     fi
#     cargo install tree-sitter-cli --locked > /dev/null 2>&1
# fi
# echo -e "${GREEN}tree-sitter: $(tree-sitter --version 2>/dev/null || echo 'instalado')${NC}"

# # 8. LazyVim + Ayu
# CONFIG="$HOME/.config/nvim"
# [ -d "$CONFIG" ] && mv "$CONFIG" "$CONFIG.backup.$(date +%s)" && echo -e "${YELLOW}Backup creado${NC}"

# echo -e "${YELLOW}Instalando LazyVim...${NC}"
echo -e "${YELLOW}tree-sitter se instalará automáticamente en Neovim${NC}"

git clone --depth 1 https://github.com/LazyVim/starter "$CONFIG"
cat > "$CONFIG/lua/plugins/ayu.lua" << 'EOF'
return { {
  "Shatur/neovim-ayu", lazy = false, priority = 1000,
  config = function()
    require("ayu").setup({ mirage = true })
    vim.cmd("colorscheme ayu")
  end
} }
EOF

# 9. Final
echo -e "${BLUE}========================================================${NC}"
echo -e "${GREEN}¡INSTALACIÓN COMPLETA!${NC}"
echo -e "   • Neovim: $NVIM_VER"
echo -e "   • LazyVim + Ayu + tree-sitter"
echo -e "   • Primera vez: espera 10-30s"
echo -e "${BLUE}========================================================${NC}"

exec nvim