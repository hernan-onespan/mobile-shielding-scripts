#!/bin/bash

source utils/utils.bash

# ================== VALIDAR DATOS DE ENTRADA ==================

if [ -z "$1" ]; then
  echo "Uso: $0 <apk_dir>"
  exit 1
  fi
  
apk_dir="${1%/}" # Eliminar barra final si existe
shielded_apk_dir=$apk_dir/shielded

if [ ! -d "$apk_dir" ]; then
  echo "El directorio '$apk_dir' no existe."
  exit 1
  fi

# ================== LÓGICA PRINCIPAL ==================

echo
info "Emulator Test $apk_dir"
echo 

# Nombre del AVD
AVD_NAME="Pixel_9"

# Nombre del paquete y actividad principal
PACKAGE_NAME=$apk_dir
MAIN_ACTIVITY=".MainActivity" 
# Si no es este, ejecutar aapt dump badging tu_app.apk | grep launchable-activity
# adb shell am start -n com.example.keylogviewer/com.example.keylogviewer.MainActivity

# Verificar si el emulador ya está corriendo
if adb get-state 1>/dev/null 2>&1; then
  echo "✅ Emulador ya está corriendo."
else
  echo "🚀 Iniciando emulador $AVD_NAME..."
  nohup emulator -avd "$AVD_NAME" > /dev/null 2>&1 &
  echo "⏳ Esperando al emulador... si no arranca solito, abri Android Studio y ejecutá el emulador"
  adb wait-for-device

  echo "🔄 Esperando boot completo..."
  while [[ "$(adb shell getprop sys.boot_completed | tr -d '\r')" != "1" ]]; do
    sleep 1
  done
  echo "✅ Emulador iniciado."
fi

# Instalar el APK
echo "📦 Instalando APK: $PACKAGE_NAME"
desinstalar_app $PACKAGE_NAME
instalar_app $PACKAGE_NAME

# Obtener el nombre del paquete y actividad principal
echo "🔍 Detectando actividad principal..."
ACTIVITY_LINE=$("$AAPT" dump badging "$APK_PATH" | grep launchable-activity)
ACTIVITY_NAME=$(echo "$ACTIVITY_LINE" | sed -n "s/.*name='\([^']*\)'.*/\1/p")
PACKAGE_NAME=$(echo "$ACTIVITY_LINE" | sed -n "s/.*package='\([^']*\)'.*/\1/p")

if [[ -z "$ACTIVITY_NAME" ]]; then
  echo "❌ No se pudo detectar la actividad principal. Verificá que aapt esté instalado."
  exit 1
fi

echo "🎯 Iniciando actividad: $ACTIVITY_NAME"
adb shell am start -n "$ACTIVITY_NAME"

