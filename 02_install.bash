#!/bin/bash

source utils/utils.bash

# ================== VALIDAR DATOS DE ENTRADA ==================

if [ -z "$1" ]; then
  echo "Uso: $0 <apk_dir>"
  exit 1
fi

apk_dir="${1%/}" # Eliminar barra final si existe

# Normalizar separadores a /
apk_dir=$(echo "$apk_dir" | sed 's|\\|/|g')

if [ ! -d "$apk_dir" ]; then
  echo "El directorio '$apk_dir' no existe."
  exit 1
fi

# ================== EXTRAER packageName ==================

# Extraer todo antes de la primera barra
packageName="${apk_dir%%/*}"

# ================== LOGICA PRINCIPAL ==================

echo
titulo "-> Instalar $apk_dir"
info "Package name: $packageName"
info "Instala la app original via USB"
info "Si hay una versión existente, primero la desinstala"
info

listar_apks "$apk_dir"

desinstalar_app "$packageName"

imprimir_certificados "$apk_dir"

instalar_app "$apk_dir"

ejecutar_app "$packageName"
