#!/bin/bash

source utils/utils.bash

# ================== VALIDAR DATOS DE ENTRADA ==================

if [ -z "$1" ]; then
  echo "Uso: $0 <prefijo_directorio>"
  exit 1
fi

DIR_PREFIX="${1%/}" # Eliminar barra final si existe

if [ -d "$DIR_PREFIX" ]; then
  MATCHED_DIRS=("$DIR_PREFIX")
else
  # Buscar todos los directorios que coincidan
  MATCHED_DIRS=($(find . -maxdepth 1 -type d -name "*${DIR_PREFIX}*" | sed 's|^\./||'))
fi

if [ ${#MATCHED_DIRS[@]} -eq 0 ]; then
  echo "❌ No se encontraron directorios que coincidan con '$DIR_PREFIX'"
  exit 1
fi

# ================== VERIFICAR DISPOSITIVO ==================
if ! adb get-state 1>/dev/null 2>&1; then
    echo "❌ No hay dispositivos ADB conectados."
    exit 1
fi

# ================== LÓGICA PRINCIPAL ==================

for apkDirectory in "${MATCHED_DIRS[@]}"; do
	echo 
    read -p "¿Procesar '$apkDirectory'? (S/n): " RESP
	if [[ -z "$RESP" || "$RESP" =~ ^[sS]$ ]]; then 

	packageName="${apkDirectory%%/*}"

	ejecutar_app "$packageName"		
	
	fi
done


	
