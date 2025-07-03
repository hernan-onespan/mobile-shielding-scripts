#!/bin/bash

# =========================================
# Biblioteca de funciones para manipular APKs y apps Android
# =========================================

# Detectar barra según sistema
slash="/"
case "$(uname -s)" in
  CYGWIN*|MINGW*|MSYS*) slash="\\" ;;
esac

# Colores ANSI para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# =========================================
# titulo (mensaje)
# Muestra un título en color verde
# =========================================
titulo() {
  local mensaje=$1
  >&2 echo -e "${GREEN}$mensaje${NC}"
}

# =========================================
# info (mensaje)
# Muestra un mensaje informativo
# =========================================
info() {
  local mensaje=$1
  >&2 echo -e "$mensaje"
}

# =========================================
# alerta (mensaje)
# Muestra un mensaje de advertencia en amarillo
# =========================================
alerta() {
  local mensaje=$1
  >&2 echo -e "${YELLOW}$mensaje${NC}"
}

# =========================================
# error (mensaje)
# Muestra un mensaje de error en rojo
# =========================================
error() {
  local mensaje=$1
  >&2 echo -e "${RED}$mensaje${NC}"
}

# =========================================
# run_cmd (comando)
# Imprime y ejecuta un comando
# =========================================
run_cmd() {
  local cmd="$1"
  info "[CMD] $cmd"
  eval "$cmd" 1>&2
}

# =========================================
# desinstalar_app (app)
# Desinstala una app del dispositivo si está instalada
# =========================================
desinstalar_app() {
  local app=$1
  if adb shell pm list packages | grep -q "$app"; then
    alerta "La app '$app' está instalada. Desinstalando..."
    run_cmd "adb uninstall '$app'"
  else
    info "La app '$app' no está instalada."
  fi
}

# =========================================
# run_apksigner (...args)
# Ejecuta apksigner según el sistema operativo
# =========================================
run_apksigner() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    run_cmd "apksigner $*"
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    run_cmd "apksigner.bat $*"
  else
    error "Sistema operativo no reconocido: $OSTYPE"
    exit 1
  fi
}

# =========================================
# imprimir_certificados (apk_dir)
# Imprime los certificados de los APKs en el directorio
# =========================================
imprimir_certificados() {
  local apk_dir=$1
  local archivoAPK
  for archivoAPK in "$apk_dir"${slash}*.apk; do
    if [ -f "$archivoAPK" ]; then
      echo "$archivoAPK"
      run_apksigner verify --print-certs "$archivoAPK" | grep certificate
      run_apksigner verify -verbose "$archivoAPK"
    fi
  done
}

# =========================================
# instalar_app (apk_dir)
# Instala todos los APKs en un directorio
# =========================================
instalar_app() {
  local apk_dir="$1"
  apk_dir=$(echo "$apk_dir" | sed 's|\\|/|g') # normalizar las rutas a barra /

  local apks

  if [ -d "$apk_dir" ]; then
    apks=("$apk_dir"/*.apk)
    if [ ${#apks[@]} -gt 0 ]; then
      titulo "\n->Instalando APKs en $apk_dir:"
      printf "  %s\n" "${apks[@]}"
      
      # Intento inicial
      if ! output=$(adb install-multiple "${apks[@]}" 2>&1); then
        echo "$output"
        if echo "$output" | grep -q "INSTALL_FAILED_TEST_ONLY"; then
          info "La app requiere el flag -t (test-only). Reintentando con 'adb install -t'..."
          run_cmd "adb install -t ${apks[*]}"
        else
          error "Fallo la instalación: $output"
        fi
      fi

    else
      error "No se encontraron archivos .apk en '$apk_dir'."
    fi
  else
    error "El directorio '$apk_dir' no existe."
  fi
}

# =========================================
# listar_apks (apk_dir)
# Lista los archivos APK en un directorio
# =========================================
listar_apks() {
  local apk_dir=$1
  echo "Archivos .apk en '$apk_dir':"
  ls -1 "$apk_dir"/*.apk
  echo ""
}

# =========================================
# run_apktool (...args)
# Ejecuta apktool según el sistema operativo
# =========================================
run_apktool() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    run_cmd "apktool $*"
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    run_cmd "apktool.bat $*"
  else
    error "Sistema operativo no reconocido: $OSTYPE"
    exit 1
  fi
}

# =========================================
# run_jadx (...args)
# Ejecuta jadx según el sistema operativo
# =========================================
run_jadx() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    run_cmd "jadx $*"
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    run_cmd "cmd.exe /c jadx.bat $*"
  else
    error "Sistema operativo no reconocido: $OSTYPE"
    exit 1
  fi
}

# =========================================
# run_jadx_gui (...args)
# Ejecuta jadx-gui según el sistema operativo
# =========================================
run_jadx_gui() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    run_cmd "jadx-gui $*"
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    run_cmd "jadx-gui-1.5.1.exe $*"
  else
    error "Sistema operativo no reconocido: $OSTYPE"
    exit 1
  fi
}

# =========================================
# firmar_app (apk_dir, archivo_keystore)
# Firma todos los APKs en un directorio usando el keystore dado
# =========================================
firmar_app() {
  local apk_dir="$1"
  local archivo_keystore="$2"
  local archivo_apk

  if [ -z "$apk_dir" ] || [ -z "$archivo_keystore" ]; then
    error "Uso: firmar_app <directorio_apks> <archivo_keystore>"
    return 1
  fi

  if [ ! -d "$apk_dir" ]; then
    error "El directorio '$apk_dir' no existe."
    return 1
  fi

  if [ ! -f "$archivo_keystore" ]; then
    error "El archivo keystore '$archivo_keystore' no existe."
    return 1
  fi

  titulo "\n-> Firmando APKs en $apk_dir usando keystore: $archivo_keystore"
  apk_dir=$(echo "$apk_dir" | sed 's|\\|/|g') # normalizar las rutas a barra /
    
  for archivo_apk in "${apk_dir}"/*.apk; do
    if [ -f "$archivo_apk" ]; then
      run_apksigner sign --ks "$archivo_keystore" --ks-pass pass:0n3sp4n "$archivo_apk"
      run_apksigner verify --print-certs "$archivo_apk" | grep certificate
      archivo_idsig="${archivo_apk}.idsig"
      if [ -f "$archivo_idsig" ]; then
        run_cmd "rm -f '$archivo_idsig'"
      fi
    fi
  done
}

# =========================================
# generar_certificado (archivo_keystore)
# Genera un keystore para firmar APKs si no existe
# =========================================
generar_certificado() {
  local archivo_keystore=$1

  titulo "\n-> Generar certificado para firmar apps"

  if [ ! -f "$archivo_keystore" ]; then
    run_cmd "keytool -genkey -v -keystore '$archivo_keystore' -alias android -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Hernan Giraudo' -storepass 0n3sp4n"
    run_cmd "keytool -list -v -keystore '$archivo_keystore' -storepass 0n3sp4n"
    info "Keystore generado en $archivo_keystore"
  else
    info "El archivo '$archivo_keystore' ya existe. No se genera uno nuevo."
  fi
}

# =========================================
# ejecutar_apkid (apk_dir)
# Ejecuta APKID sobre los APKs del directorio
# =========================================
ejecutar_apkid() {
  local apk_dir=$1
  local output_dir="$apk_dir/07_apkid"
  local archivo_apk filename output_file

  mkdir -p "$output_dir"

  for archivo_apk in "$apk_dir"/*.apk; do
    if [ -f "$archivo_apk" ]; then
      filename=$(basename "$archivo_apk")
      output_file="$output_dir/$filename.log"
      info "Analizando con APKID: $archivo_apk"
      run_cmd "/home/hernan/rasp/tools/APKiD/docker/apkid.sh --verbose '$archivo_apk' > '$output_file'"
    fi
  done
}

# =========================================
# decompilar_apktool (apk_dir, decompiled_dir)
# Descompila los APKs usando apktool
# =========================================
decompilar_apktool() {
  local apk_dir=$1
  local decompiled_dir=$2
  local archivoAPK nombreArchivo nombreArchivoSinExtension

  mkdir -p "$decompiled_dir"

  for archivoAPK in "$apk_dir"/*.apk; do
    if [ -f "$archivoAPK" ]; then
      nombreArchivo=$(basename "$archivoAPK")
      nombreArchivoSinExtension="${nombreArchivo%.*}"
      info "Decompilando $archivoAPK con apktool..."
      run_apktool d "$archivoAPK" -o "$decompiled_dir/$nombreArchivoSinExtension" -f
    fi
  done
}

# =========================================
# decompilar_jadx (apk_dir, decompiled_dir)
# Descompila los APKs usando JADX
# =========================================
decompilar_jadx() {
  local apk_dir=$1
  local decompiled_dir=$2
  local archivoAPK nombreArchivo nombreArchivoSinExtension

  mkdir -p "$decompiled_dir"

  for archivoAPK in "$apk_dir"/*.apk; do
    if [ -f "$archivoAPK" ]; then
      nombreArchivo=$(basename "$archivoAPK")
      nombreArchivoSinExtension="${nombreArchivo%.*}"
      info "Decompilando $archivoAPK con jadx..."
      run_jadx --no-res "$archivoAPK" -d "$decompiled_dir/$nombreArchivoSinExtension"
    fi
  done
}

# =========================================
# jadx_gui (apk_dir)
# Abre los APKs en JADX-GUI
# =========================================
jadx_gui() {
  local apk_dir=$1
  local archivoAPK

  for archivoAPK in "$apk_dir"/*.apk; do
    if [ -f "$archivoAPK" ]; then
      info "Abriendo en JADX GUI: $archivoAPK"
      run_jadx_gui "$archivoAPK"
    fi
  done
}

# =========================================
# apkleaks (apk_dir, output_dir)
# Ejecuta apkleaks sobre los APKs
# =========================================
apkleaks() {
  local apk_dir=$1
  local output_dir=$2
  local apk nombre_base salida
  local ENTORNO=~/rasp/tools/apkleaks/mi_entorno
  local APKLEAKS=~/rasp/tools/apkleaks/apkleaks.py

  if [ ! -d "$apk_dir" ]; then
    error "El directorio '$apk_dir' no existe."
    exit 1
  fi

  mkdir -p "$output_dir"
  source "$ENTORNO/bin/activate"

  for apk in "$apk_dir"/*.apk; do
    [ -e "$apk" ] || continue
    nombre_base=$(basename "$apk" .apk)
    salida="$output_dir/${nombre_base}_results.json"
    info "Analizando $apk con apkleaks..."
    run_cmd "python '$APKLEAKS' -f '$apk' -o '$salida' --json"
  done

  deactivate
  info "Análisis con apkleaks completado."
}

# =========================================
# ejecutar_app (app)
# Ejecuta una app instalada en el dispositivo Android
# =========================================
ejecutar_app() {
  local app=$1

  if adb shell pm list packages | grep -q "$app"; then
    titulo " " 
    titulo "Iniciando la app '$app' en el dispositivo..."
    run_cmd "adb shell monkey -p '$app' -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1"
    if [ $? -eq 0 ]; then
      info "✅ La app '$app' se inició correctamente."
    else
      error "❌ Ocurrió un error al intentar iniciar la app '$app'."
    fi
  else
    error "La app '$app' no está instalada en el dispositivo."
  fi
}

# =========================================
# chequear_directorio (dir)
# Crea un directorio si no existe
# =========================================
chequear_directorio() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    run_cmd "mkdir -p '$dir'"
  fi
}

# =========================================
# blindar_local (packageName, shieldingConfigurationName)
# Blinda una APK localmente usando una configuración específica
# Retorna por stdout el path del directorio donde queda la app blindada
# =========================================
blindar_local() {
  local packageName="$1"
  local shieldingConfigurationName="$2"

  if [[ -z "$packageName" || -z "$shieldingConfigurationName" ]]; then
    >&2 echo "Error: Uso: blindar_local <packageName> <shieldingConfigurationName>"
    return 1
  fi

  local unshieldedApkFile="${packageName}${slash}base.apk"
  local shieldedApkDir="${packageName}${slash}shielded${slash}${shieldingConfigurationName}"
  local shieldedApkFile="${shieldedApkDir}${slash}base.apk"
  local shieldingConfigurationFile="${shieldingConfigurationDir}${slash}${shieldingConfigurationName}.xml"

  titulo "\n-> Blindando $packageName con configuración $shieldingConfigurationName"
  run_cmd "java -jar \"$shielderJar\" \"$unshieldedApkFile\" --config \"$shieldingConfigurationFile\" --output \"$shieldedApkFile\""

  echo "$shieldedApkDir"
}
