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

echo "Directorios en '$apk_dir/decompiled.apktool':"
decompiled_apk_dir=$apk_dir/decompiled.apktool

ls -d $decompiled_apk_dir/*/ 
echo " "

desinstalar_app "$apk_dir"

archivo_keystore="utils/keystore"

generar_certificado $archivo_keystore

# Iterar sobre cada archivo en el directorio
for dir in "$decompiled_apk_dir"/*/; do
	dir="${dir%/}"
	archivoAPK=$dir.apk
    echo -e "${GREEN}Compilando $archivoAPK ${NC}"
	apktool.bat b $dir -o $archivoAPK
done

firmar_app $decompiled_apk_dir $archivo_keystore

instalar_app $decompiled_apk_dir
