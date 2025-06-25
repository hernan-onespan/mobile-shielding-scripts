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

# ================== LÓGICA PRINCIPAL ==================


imprimir_certificados "$apk_dir"