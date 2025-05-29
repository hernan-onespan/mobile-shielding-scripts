#!/bin/bash

source utils/utils.bash

# ================== VALIDAR DATOS DE ENTRADA ==================

if [ -z "$1" ]; then
  echo "Uso: $0 <apk_dir>"
  exit 1
  fi
  
apk_dir="${1%/}" # Eliminar barra final si existe

if [ ! -d "$apk_dir" ]; then
  echo "El directorio '$apk_dir' no existe."
  exit 1
  fi

# ================== LOGICA PRINCIPAL ==================

echo
info "Sideloading Test $apk_dir"
echo Instala la app via USB, en lugar de hacerlo desde una tienda oficial
echo 

listar_apks "$apk_dir"

desinstalar_app "$apk_dir"

imprimir_certificados "$apk_dir"  

instalar_app "$apk_dir"  





