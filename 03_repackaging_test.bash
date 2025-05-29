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

echo
info "Repackaging Test $apk_dir"
echo Firma la app con un certificado distinto y la vuelve a instalar
echo 

desinstalar_app "$apk_dir"

listar_apks "$apk_dir"

repackaged_apk_dir=$apk_dir/03_repackaged

# Crear una copia de los apks originales
mkdir -p $repackaged_apk_dir # -p: no falla si el directorio ya existe
cp $apk_dir/*.apk $repackaged_apk_dir

archivo_keystore="utils/keystore"

generar_certificado $archivo_keystore

firmar_app $repackaged_apk_dir $archivo_keystore

instalar_app $repackaged_apk_dir
