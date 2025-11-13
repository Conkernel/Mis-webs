#!/bin/bash

# --- 1. VERIFICACIÓN DE PRIVILEGIOS (EUID) ---

# EUID (Effective User ID) es 0 si el script se ejecuta como root (o con sudo).
if [ "$EUID" -ne 0 ]; then
    # Si no es root, muestra un error y sale
    echo "🚨 ERROR: Este script debe ejecutarse con privilegios de root (sudo)."
    echo "Por favor, inténtalo de nuevo con: sudo bash"
    exit 1
fi
# --- 2. VERIFICACIÓN DE USUARIO Y EJECUCIÓN ---
# Si llegamos aquí, sabemos que estamos usando sudo/root.
# El usuario original se almacena en la variable 'SUDO_USER'
# (si fue llamado con sudo). Si fue llamado directamente como root,
# SUDO_USER estará vacío.
if [ -n "$SUDO_USER" ]; then
    USUARIO_EJECUTOR="$SUDO_USER"
else
    # Si SUDO_USER está vacío, obtenemos el nombre del usuario root
    USUARIO_EJECUTOR=$(whoami) 
fi
printf "✅ Verificación de privilegios superada.\n\n"
printf "Usuario original que lanzó el script: $USUARIO_EJECUTOR\n\n"

if [ "$USUARIO_EJECUTOR" == "root" ]; then
    HOMEDIR="/root"
else    
    # Método más robusto: usar getent passwd o ~ si estamos en el entorno del usuario
    # Pero para este caso simple, la ruta /home/ funciona si el usuario no es root.
    HOMEDIR="/home/$USUARIO_EJECUTOR"
fi

# Detección del Sistema Operativo para la instalación de paquetes
detectar_distro() {
    # 1. Método principal: Usar /etc/os-release (ESTÁNDAR MODERNO)
    if [ -f "/etc/os-release" ]; then
        # Carga las variables del archivo (NAME, ID, VERSION_ID, etc.)
        . /etc/os-release
        # Convierte el ID a minúsculas para comparaciones consistentes
        local ID_MINUSCULAS=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
        # Comprobación de distribuciones específicas
        case "$ID_MINUSCULAS" in
            # Familias Debian
            debian)
                PACKAGE_FOR_LS="exa"
                INSTALL="apt install -y"
                UPDATE="apt update"
                echo $ID_MINUSCULAS
                printf "Sistema detectado: Debian. Usando 'exa' para la instalación.\n\n"
                ;;
            ubuntu)
                echo "Distribución: Ubuntu"
                INSTALL="apt install -y"
                echo $ID_MINUSCULAS
                UPDATE="apt update"                
                PACKAGE_FOR_LS="exa"
                printf "Sistema detectado: Ubuntu. Usando 'exa' para la instalación.\n\n"
                ;;
            rhel)
                PACKAGE_FOR_LS="eza"
                UPDATE="dns update"
                INSTALL="dnf install -y"                
                echo $ID_MINUSCULAS
                printf "Sistema detectado: RedHat. Usando 'eza' para la instalación.\n\n"
                ;;
            centos)
                echo $ID_MINUSCULAS
                UPDATE="dns update"                
                INSTALL="dnf install -y"                
                ACKAGE_FOR_LS="eza"
                printf "Sistema detectado: Centos. Usando 'eza' para la instalación.\n\n"
                ;;

            arch | archarm)
                UPDATE="pacman -Sy"
                echo $ID_MINUSCULAS
                INSTALL="pacman -S --noconfirm"                
                PACKAGE_FOR_LS="eza"
                printf "Sistema detectado: Arch. Usando 'eza' para la instalación.\n\n"
                ;;
            
            # Si no coincide exactamente, muestra el nombre (ej. Mint, Pop!_OS)
            *)
                echo "La distro es $ID_MINUSCULAS"
                echo "Distribución (Base OS-RELEASE): $NAME $VERSION_ID"
                echo "Mejorar script para darle soporte según versión"                
                exit
                ;;
        esac
        
    # 2. Método de respaldo: Usar lsb_release (LEGADO)
    elif command -v lsb_release &> /dev/null; then
        echo "Distribución (Base LSB): $(lsb_release -ds)"
        echo "Mejorar script para darle soporte según versión"
        exit

    # 3. Método de último recurso: Archivos específicos
    elif [ -f "/etc/redhat-release" ]; then
        # Atrapa versiones muy antiguas de RHEL/CentOS
        echo "Distribución (Base RedHat-release): $(cat /etc/redhat-release)"
        echo "Mejorar script para darle soporte según versión"
        exit
    else
        echo "Error: No se pudo detectar la distribución de Linux."
        exit
    fi
}
detectar_distro


# Instalación de paquetes
printf "Actualizando repositorios...\n\n"
$UPDATE
printf "Instalando paquetes esenciales...\n\n"
APT_PACKAGES="zsh bat git curl ripgrep $PACKAGE_FOR_LS"
$INSTALL $APT_PACKAGES
# Verificar si la instalación de apt fue exitosa
if [ $? -ne 0 ]; then
    printf "ERROR: Falló la instalación de paquetes. Por favor, revisa los errores.\n\n" >&2
    exit 1
else
    printf "Paquetes instalados correctamente.\n\n"
fi

# Backup previo de /etc/zsh
printf "Haciendo backup de la configuración global de Zsh...\n\n"
if [ -d /etc/zsh ]; then
    printf "Copia de seguridad de /etc/zsh en /etc/zsh.old... \n\n"
    if [ -d /etc/zsh.old ]; then
        printf "El directorio /etc/zsh.old ya existe. Eliminándolo para evitar conflictos.\n\n"
        rm -rf /etc/zsh.old
    fi
    mv /etc/zsh /etc/zsh.old
    mkdir -p /etc/zsh    
else
    mkdir -p /etc/zsh
fi


# Backup previo de ~/.config/zsh
printf "Haciendo backup de la configuración de usuario de Zsh...\n\n"
if [ -d $HOMEDIR/.config/zsh ]; then
    printf "Copia de seguridad de $HOMEDIR/.config/zsh en $HOMEDIR/.config/zsh.old... \n\n"
    if [ -d /etc/zsh.old ]; then
        printf "El directorio $HOMEDIR/.config/zsh.old ya existe. Eliminándolo para evitar conflictos.\n\n"
        rm -rf $HOMEDIR/.config/zsh.old
    fi
    mv $HOMEDIR/.config/zsh /$HOMEDIR/.config/zsh.old
else
    printf "No existía perfil de ZSH de este usuario previamente \n\n"
fi



CONFIG_FILE="/etc/zsh/zshrc"
MARKER_START="# === ZSH XDG CONFIG (added by script) ==="
MARKER_END="# === END ZSH XDG CONFIG ==="

# Contenido a añadir (entre marcadores para fácil detección)
CONTENT=$(cat << 'EOF'
ZSH_ENV_USER="${HOME}/.config/zsh/.zshenv"
if [ -f "$ZSH_ENV_USER" ]; then
    source "$ZSH_ENV_USER"
fi
EOF
)
touch $HOMEDIR/.zshrc
# Verificar si ya existe el bloque
if ! grep -q "$MARKER_START" "$CONFIG_FILE" 2>/dev/null; then
    echo -e "\n$MARKER_START" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "$CONTENT" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo -e "$MARKER_END\n" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "Configuración añadida a $CONFIG_FILE"
else
    echo "Configuración ya presente en $CONFIG_FILE. Nada que hacer."
fi

# Crear ruta para fzf
printf "Creando ruta local de fzf \n\n"
mkdir -p $HOMEDIR/.fzf





echo "Clonando config de zsh de repo de Conkernel..."
git clone https://github.com/Conkernel/zsh.git $HOMEDIR/.config/zsh
rm -rf $HOMEDIR/powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOMEDIR/powerlevel10k
# echo 'source $HOMEDIR/powerlevel10k/powerlevel10k.zsh-theme' >>$HOMEDIR/.config/zsh/.zshrc
rm $HOMEDIR/powerlevel10k/.git -rf
rm $HOMEDIR/.fzf/.git -rf

# Permisos
printf "Adecuando permisos para $USUARIO_EJECUTOR \n\n"
chown -R $USUARIO_EJECUTOR:$USUARIO_EJECUTOR $HOMEDIR/

exit 0

