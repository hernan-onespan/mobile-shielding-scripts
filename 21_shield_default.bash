#!/bin/bash

# ================== CONFIGURACIÓN ==================
source "$(dirname "$0")/utils/config.env"
source "$(dirname "$0")/utils/utils.bash"
# ===================================================

# ================== VALIDAR DATOS DE ENTRADA ==================

if [ -z "$1" ]; then
  echo "Uso: $0 <prefijo_directorio>"
  exit 1
fi

DIR_PREFIX="${1%/}" # Eliminar barra final si existe

# Buscar todos los directorios que coincidan
MATCHED_DIRS=($(find . -maxdepth 1 -type d -name "*${DIR_PREFIX}*" | sed 's|^\./||'))

if [ ${#MATCHED_DIRS[@]} -eq 0 ]; then
  echo "❌ No se encontraron directorios que coincidan con '$DIR_PREFIX'"
  exit 1
fi

# ================== VERIFICAR DISPOSITIVO ==================
if ! adb get-state 1>/dev/null 2>&1; then
    echo "❌ No hay dispositivos ADB conectados."
    exit 1
fi

# ================== CERTIFICADO PARA FIRMAR APPS ==================

archivo_keystore="utils/keystore"

generar_certificado $archivo_keystore

# ================== LOOP POR DIRECTORIOS ==================

for packageName in "${MATCHED_DIRS[@]}"; do
	echo 
    read -p "¿Procesar '$packageName'? (S/n): " RESP
	if [[ -z "$RESP" || "$RESP" =~ ^[sS]$ ]]; then 

        if [ ! -d "$packageName" ]; then
            echo "El directorio '$packageName' no existe (¿Se eliminó?)."
            continue
        fi

		shieldingConfigurationName="default" #default.xml
		
		shieldedApkDir=$(blindar_local "$packageName" "$shieldingConfigurationName")
			
		alerta "APK blindada en: $shieldedApkDir"
		
		firmar_app "$shieldedApkDir" "$archivo_keystore"
		
		desinstalar_app "$packageName"		
		
		instalar_app "$shieldedApkDir"
		
		ejecutar_app "$packageName"		
	fi
done

