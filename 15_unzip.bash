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

unzipped_dir=$apk_dir/15_unzipped
mkdir -p $unzipped_dir

# Iterar sobre cada archivo en el directorio
for archivoAPK in "$apk_dir"/*.apk; do
  if [ -f "$archivoAPK" ]; then
    archivoZIP="${archivoAPK%.*}.zip" # reemplaza .apk por .zip
	nombreArchivo=$(basename "$archivoAPK")
	cp $archivoAPK $archivoZIP 
        echo unzip -o -q $archivoZIP -d $unzipped_dir/$nombreArchivo # o: overwrite q: quiet
        unzip -o -q $archivoZIP -d $unzipped_dir/$nombreArchivo # o: overwrite q: quiet
	rm $archivoZIP
  fi
done

exit 0




