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

# ================== LÓGICA PRINCIPAL ==================

archivo_keystore="utils/keystore"

generar_certificado $archivo_keystore

imprimir_certificados "$apk_dir"

firmar_app "$apk_dir" "$archivo_keystore"