#!/bin/bash

source utils/utils.bash

FRIDA_SCRIPT="utils/frida/arrow.js"  # Script Frida a inyectar

# ================== VERIFICAR CLIENTE FRIDA ==================
FRIDA_VERSION=$(frida --version 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$FRIDA_VERSION" ]; then
    echo "❌ No se detecta el cliente Frida."
    echo "👉 Por favor, asegurate de haber activado el entorno y que el cliente 'frida' esté disponible en el PATH."
    echo "🛑 Abortando."
    exit 1
else
    echo "🧩 Frida CLI activo. Versión: $FRIDA_VERSION"
fi

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

# ================== LOOP POR DIRECTORIOS ==================

for PACKAGE_NAME in "${MATCHED_DIRS[@]}"; do
    read -p "¿Procesar '$PACKAGE_NAME'? (s/N): " RESP
    if [[ "$RESP" =~ ^[sS]$ ]]; then

        if [ ! -d "$PACKAGE_NAME" ]; then
            echo "El directorio '$PACKAGE_NAME' no existe (¿se eliminó?)."
            continue
        fi

        echo "🔍 Verificando si $PACKAGE_NAME está instalada..."
        if ! adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
            echo "📦 App no encontrada. Instalando APK..."
            APK_PATH="$PACKAGE_NAME/base.apk"
            if [ ! -f "$APK_PATH" ]; then
                echo "❌ No se encuentra $APK_PATH"
                continue
            fi
            adb install "$APK_PATH"
            if [ $? -ne 0 ]; then
                echo "❌ Error al instalar el APK."
                continue
            fi
        else
            echo "✅ App ya está instalada."
        fi

        echo "🔍 Verificando si la app está en ejecución..."
        PIDS=$(adb shell ps -A | grep "$PACKAGE_NAME" | awk '{print $2}')

        if [ -z "$PIDS" ]; then
            echo "🚀 La app no está corriendo. Iniciando..."
            adb shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
            sleep 3
            PIDS=$(adb shell pidof "$PACKAGE_NAME")
            if [ -z "$PIDS" ]; then
                echo "❌ No se pudo iniciar la app."
                continue
            fi
        fi

        PID_COUNT=$(echo "$PIDS" | wc -w)
        echo "✅ Se encontraron $PID_COUNT procesos para $PACKAGE_NAME: $PIDS"

        # Inyectar Frida en todos los procesos
        for PID in $PIDS; do
            echo "📌 Inyectando script Frida en PID $PID..."
            frida -U -p "$PID" -l "$FRIDA_SCRIPT" || echo "⚠️ Falló la inyección en PID $PID"
        done
    fi
done

