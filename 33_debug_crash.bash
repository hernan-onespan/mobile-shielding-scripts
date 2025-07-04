#!/bin/bash

source utils/utils.bash
TMP_LOG="crashlog.txt"

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
for PACKAGE_NAME in "${MATCHED_DIRS[@]}"; do
	echo 
    read -p "¿Procesar '$PACKAGE_NAME'? (S/n): " RESP
	if [[ -z "$RESP" || "$RESP" =~ ^[sS]$ ]]; then 

	echo "🧹 Limpiando logs previos..."
	adb logcat -c
	
	echo "🚀 Ejecutando la app..."
	adb shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1
	
	echo "⏳ Esperando que se produzca el crash..."
	sleep 5
	
	echo "🪵 Guardando logs completos..."
	adb logcat -d -v time > "$FULL_LOG"

	echo "🔍 Filtrando posibles errores..."
	grep -iE "FATAL EXCEPTION|AndroidRuntime|Process.*has died|force.*closing" "$FULL_LOG" > "$CRASH_LOG"
		
	echo
	echo "📄 Logs guardados:"
	echo "  - Completo: $FULL_LOG"
	echo "  - Errores : $CRASH_LOG"
	echo

	if grep -qi "FATAL EXCEPTION" "$TMP_LOG"; then
	  echo "❗️ Crash detectado:"
	  grep -A 10 "FATAL EXCEPTION" "$TMP_LOG"
	else
	  echo "✅ No se detectó crash en los logs. Verifica manualmente en $TMP_LOG"
	fi

	echo
	echo "✅ Análisis completado."
	
	fi
done


	


