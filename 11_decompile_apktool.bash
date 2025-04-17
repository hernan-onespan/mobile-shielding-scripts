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

listar_apks $apk_dir

decompiled_dir=$apk_dir/decompiled.apktool
mkdir -p $decompiled_dir

# Iterar sobre cada archivo en el directorio
for archivoAPK in "$apk_dir"/*.apk; do
  if [ -f "$archivoAPK" ]; then
	nombreArchivo=$(basename "$archivoAPK")
	nombreArchivoSinExtension="${nombreArchivo%.*}" 
	echo $nombreArchivo 
	apktool.bat d $archivoAPK -o $decompiled_dir/$nombreArchivoSinExtension -f # Descompilar el archivo con APK tool
  fi
done

exit 0




