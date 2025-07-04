#!/bin/bash

# ================== CONFIGURACIÓN ==================
source "$(dirname "$0")/utils/config.env"
source "$(dirname "$0")/utils/utils.bash"
# ===================================================

titulo "\n-> Blindar una app por linea de comando"

# ================== VALIDAR DATOS DE ENTRADA ==================

# Validar primer parámetro (nombre del paquete)
if [ -z "$1" ]; then
  echo "Uso: $0 <nombre_paquete> [archivo_configuracion]"
  exit 1
fi

packageName="$1"
shieldingConfigurationName="${2:-default}"  # Usa 'default' si no se especifica

# Informar si no se especificó archivo de configuración
if [ -z "$2" ]; then
  echo "Archivo de configuración no especificado. Usando 'default'"
fi

# Ruta al archivo de configuración
shieldingConfigurationFile="${shieldingConfigurationDir}/${shieldingConfigurationName}.xml"

# Si el archivo especificado no existe, intentar con default.xml
if [ ! -f "$shieldingConfigurationFile" ]; then
  echo "⚠️  Archivo '$shieldingConfigurationFile' no encontrado. Probando con 'default.xml'"
  shieldingConfigurationFile="${shieldingConfigurationDir}/default.xml"
fi

# Validar existencia del archivo de configuración final
if [ ! -f "$shieldingConfigurationFile" ]; then
  echo "❌ Archivo de configuración 'default.xml' no encontrado en: $shieldingConfigurationDir"
  exit 1
fi

echo "✅ Usando configuración: $shieldingConfigurationFile"

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

# ================== CERTIFICADO PARA FIRMAR APPS ==================

archivo_keystore="utils/keystore"

generar_certificado $archivo_keystore

# ================== LOOP POR DIRECTORIOS ==================

for apkDirectory in "${MATCHED_DIRS[@]}"; do
	echo 
    read -p "¿Procesar '$apkDirectory'? (S/n): " RESP
	if [[ -z "$RESP" || "$RESP" =~ ^[sS]$ ]]; then 

        if [ ! -d "$apkDirectory" ]; then
            echo "El directorio '$apkDirectory' no existe (¿Se eliminó?)."
            continue
        fi

		# Extraer todo antes de la primera barra
		packageName="${apkDirectory%%/*}"
		
		shieldedBaseDir=$apkDirectory/shielded
		chequear_directorio "${shieldedBaseDir}"

		shieldedApkDir="${shieldedBaseDir}/${shieldingConfigurationName}"
		chequear_directorio "${shieldedApkDir}"

		titulo "\n-> Hacer una copia para firmar con el certificado que vamos a usar despues de blindar"
		run_cmd "cp $apkDirectory/*.apk $shieldedBaseDir" # 
						
		firmar_app "$shieldedBaseDir" "$archivo_keystore" # Firmar antes de blindar para evitar repackaging

		blindar_apks "$shieldedBaseDir" "$shieldingConfigurationFile"
					
		titulo "-> APK blindada en: $shieldedApkDir"
		
		firmar_app "$shieldedApkDir" "$archivo_keystore"
		
		desinstalar_app "$packageName"		
		
		instalar_app "$shieldedApkDir"
		
		ejecutar_app "$packageName"		
	fi
done

