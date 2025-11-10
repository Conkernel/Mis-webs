#!/bin/bash

# Script de instalación de paquetes mínimos, configuración de sistema,
# instalación de Docker y configuración de Bash para Ubuntu.
# Ejecutar como usuario NO root (ej: ./install.sh)

set -euo pipefail

USERNAME="$USER"

if [ "$(id -u)" = "0" ]; then
    echo "Este script debe ejecutarse como usuario NO root."
    exit 1
fi

echo "Iniciando instalación para usuario: $USERNAME"

# --- 1. Actualizar e instalar paquetes mínimos ---
echo "Instalando paquetes mínimos..."
sudo apt update
sudo apt install -y \
    vim nano sudo jq golang curl wget git gpg \
    open-vm-tools apt-transport-https ca-certificates \
    software-properties-common bash-completion \
    iputils-ping dnsutils net-tools traceroute \
    man manpages-es dialog zsh psmisc tree \
    mosh telnet file rsync apt-utils ansible sshpass

# --- 2. Sudo sin contraseña ---
echo "Configurando sudo sin contraseña para $USERNAME..."
sudo mkdir -p /etc/sudoers.d
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/nopasswd > /dev/null
sudo chmod 0440 /etc/sudoers.d/nopasswd

# --- 3. Desactivar swap ---
echo "Desactivando swap..."
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

# --- 4. Instalar Docker (CORREGIDO) ---
echo "Instalando Docker..."

# Limpiar configuraciones previas
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.gpg

# Descargar y convertir clave GPG
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Obtener VERSION_CODENAME correctamente
source /etc/os-release
CODENAME="$VERSION_CODENAME"

# Escribir el repositorio con variable ya expandida
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $CODENAME stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualizar e instalar
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Añadir usuario al grupo docker
sudo usermod -aG docker "$USERNAME"
echo "Usuario $USERNAME añadido al grupo docker (reinicia sesión)"

# --- 5. Configurar /etc/bash.bashrc ---
echo "Configurando /etc/bash.bashrc..."
sudo cp /etc/bash.bashrc /etc/bash.bashrc.bak 2>/dev/null || true
cat << 'EOF' | sudo tee -a /etc/bash.bashrc > /dev/null

# --- Configuración personalizada ---
PS1='\[\e[1;32m\]\u@\h:\[\e[1;34m\]\w\[\e[0m\]\$ '

if [ -f /etc/bash_aliases ]; then
    . /etc/bash_aliases
fi

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01;34:quote=01'
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;31m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[1;44;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias less='less -R'
fi
EOF

# --- 6. Alias globales ---
echo "Configurando alias globales..."
sudo touch /etc/bash_aliases
{
    echo "alias cc='clear'"
    echo "alias ll='ls -lahF'"
    echo "alias kk='kubectl'"
} | sudo tee /etc/bash_aliases > /dev/null

# --- 7. Bash completion ---
echo "Configurando completion en ~/.bashrc..."
grep -q "bash_completion" ~/.bashrc || cat << 'EOT' >> ~/.bashrc

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi
EOT

# --- 8. Completions de Docker ---
echo "Generando completions de Docker..."
mkdir -p ~/.local/share/bash-completion/completions
docker completion bash > ~/.local/share/bash-completion/completions/docker 2>/dev/null || echo "Docker no está listo aún para completion"

echo "¡Instalación completada!"
echo ""
echo "ACCIONES PENDIENTES:"
echo "1. Reinicia sesión: exec su - $USERNAME"
echo "2. Aplica grupo docker: newgrp docker"
echo "3. Prueba: docker run hello-world"
echo "4. Prueba alias: ll"
echo ""
echo "¡Todo listo!"
