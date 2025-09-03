#!/bin/bash



adb install -r utils/keylogger.apk
echo "✅ Keylogger instalado"

adb uninstall com.example.keylogviewer
adb install -r utils/keylogviewer.apk
echo "✅ Keylog viewer instalado"
echo
echo "Configurar el teclado Keylog Keyboard (Ajustes > Administracion General > Lista y teclado predeterminado > Teclado predeterminado)"
echo "Abrir la app y tipear" 
echo "Abrir la app Keylog Viewer"

