#!/bin/bash

# ================== CONFIGURACIÓN ==================
source "$(dirname "$0")/utils/config.env"
source "$(dirname "$0")/utils/utils.bash"
# ===================================================

# ================== VALIDAR DATOS DE ENTRADA ==================

if [ -z "$1" ]; then
  echo "Uso: $0 <patron>"
  exit 1
fi

DIR_PREFIX="${1%/}" # Eliminar barra final si existe

# Buscar todos los directorios que coincidan
MATCHED_DIRS=($(find . -maxdepth 1 -type d -name "*${DIR_PREFIX}*" | sed 's|^\./||'))

if [ ${#MATCHED_DIRS[@]} -eq 0 ]; then
  echo "❌ No se encontraron directorios que coincidan con '$DIR_PREFIX'"
  exit 1
fi

# ================== LOOP POR DIRECTORIOS ==================

for apkDirectory in "${MATCHED_DIRS[@]}"; do
	echo 
    read -p "¿Procesar '$apkDirectory'? (S/n): " RESP
	if [[ -z "$RESP" || "$RESP" =~ ^[sS]$ ]]; then 

        if [ ! -d "$apkDirectory" ]; then
            echo "El directorio '$apkDirectory' no existe (¿Se eliminó?)."
            continue
        fi

		merged_apk=$apkDirectory/merged/base.apk

		command="java -jar $apkeditorJar m -i $apkDirectory -o $merged_apk"
		
		run_cmd "$command"

		alerta "APK unico creado en en: $merged_apk"
		
	fi
done

