#!/bin/bash

source utils/utils.bash

# ================== VALIDAR DATOS DE ENTRADA ==================

if [ -z "$1" ]; then
  echo "Uso: $0 <apk_dir>"
  exit 1
  fi
  
apk_dir="${1%/}" # Eliminar barra final si existe
shielded_apk_dir=$apk_dir/shielded

if [ ! -d "$apk_dir" ]; then
  echo "El directorio '$apk_dir' no existe."
  exit 1
  fi

if [ ! -d "$shielded_apk_dir" ]; then
  echo "El directorio '$shielded_apk_dir' no existe. Blinde la aplicacion primero."
  exit 1
  fi

# ================== LÓGICA PRINCIPAL ==================

echo
info "Install Shielded App Test $apk_dir"
echo Instala la version blindada por 04_shield_apks_in_portal.bash
echo 

desinstalar_app $apk_dir

listar_apks $shielded_apk_dir

archivo_keystore=utils/keystore

generar_certificado $archivo_keystore

firmar_app $shielded_apk_dir $archivo_keystore

instalar_app $shielded_apk_dir
