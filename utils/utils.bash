#!/bin/bash

# Colores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

info() {
	mensaje=$1
	echo -e "${GREEN}$mensaje${NC}"
}

alerta() {
	mensaje=$1
	echo -e "${YELLOW}$mensaje${NC}"
}

error() {
	mensaje=$1
	echo -e "${RED}$mensaje${NC}"
}


# desinstalar_app(app)
# Desinstala una app del dispositivo móvil
#
# Ejemplo: desinstalar_app ar.com.santander.rio.mbanking
desinstalar_app() {
	app=$1
	if adb shell pm list packages | grep -q "$app"; then
	  alerta "La app '$app' está instalada. Desinstalando..."
	  adb uninstall "$app"
	else
	  info "La app '$app' no está instalada."
	fi
}

# run_apksigner ()
# 
# Llama al comando que corresponda en funcion del sistema operativo
#
run_apksigner() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        apksigner "$@"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        apksigner.bat "$@"
    else
        echo "Sistema operativo no reconocido: $OSTYPE"
        exit 1
    fi
} 

# imprimir_certificados(app_dir)
# Busca todos los archivos .apk en el directorio e imprime el certificado
#
# Ejemplo: imprimir_certificados ar.com.santander.rio.mbanking
imprimir_certificados() {
	apk_dir=$1
	# Iterar sobre cada archivo en el directorio
	for archivoAPK in "$apk_dir"/*.apk; do
	  if [ -f "$archivoAPK" ]; then
		echo "$archivoAPK"
		run_apksigner verify --print-certs $archivoAPK | grep certificate # Verificar certificado
		run_apksigner verify -verbose $archivoAPK
	  fi
	done
}

# instalar_app(app_dir)
# Instala todos los archivos .apk que existen en un directorio
#
# Ejemplo: instalar_app ar.com.santander.rio.mbanking
instalar_app() {
	apk_dir=$1
	if [ -d "$apk_dir" ]; then
	  apks=("$apk_dir"/*.apk)
	  if [ ${#apks[@]} -gt 0 ]; then
		alerta "Instalando APKs con adb install-multiple:"
		printf "  %s\n" "${apks[@]}"
		adb install-multiple "${apks[@]}"
	  else
		error "No se encontraron archivos .apk en '$apk_dir'."
	  fi
	else
	  error "El directorio '$apk_dir' no existe."
	fi
}

# listar_apks(apk_dir)
# Muestra todos los archivos .apk que existen en un directorio
#
# Ejemplo: listar_apks ar.com.santander.rio.mbanking
listar_apks() {
  apk_dir=$1
  echo "Archivos .apk en '$apk_dir':"
  ls -1 $apk_dir/*.apk
  echo " "
 }

# run_apktool ()
# 
# Llama al comando que corresponda en funcion del sistema operativo
#
run_apktool() {
    echo run_apktool "$@" 
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        apktool "$@"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        apktool.bat "$@"
    else
        echo "Sistema operativo no reconocido: $OSTYPE"
        exit 1
    fi
} 

# run_jadx ()
# 
# Llama al comando que corresponda en funcion del sistema operativo
#
run_jadx() {
    echo jadx "$@" 
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        jadx "$@"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        cmd.exe /c jadx.bat "$@"
    else
        echo "Sistema operativo no reconocido: $OSTYPE"
        exit 1
    fi
} 

# run_jadx_gui ()
# 
# Llama al comando que corresponda en funcion del sistema operativo
#
run_jadx_gui() {
    echo jadx "$@" 
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        jadx-gui "$@"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        cmd.exe /c jadx-gui.bat "$@"
    else
        echo "Sistema operativo no reconocido: $OSTYPE"
        exit 1
    fi
} 


# firmar (apk_dir keystore)
#
firmar_app() {
  apk_dir=$1
  archivo_keystore=$2
  echo archivo_keystore: $archivo_keystore
  # Iterar sobre cada archivo en el directorio
  for archivo_apk in "$apk_dir"/*.apk; do
	if [ -f "$archivo_apk" ]; then
	  filename=$(basename "$archivo_apk")
      run_apksigner sign --ks $archivo_keystore --ks-pass pass:0n3sp4n $archivo_apk
      run_apksigner verify --print-certs $archivo_apk | grep certificate # Verificar
	  rm $archivo_apk.idsig # eliminar archivo temporal
      fi
	done
}

# generar_certificado(archivo_keystore)
# Genera un keystore en el archivo indicado para firmar las apps
generar_certificado() {
  archivo_keystore=$1
  if [ ! -f $archivo_keystore ]; then
    keytool -genkey -v -keystore $archivo_keystore -alias android -keyalg RSA -keysize 2048 -validity 10000 -dname CN="Hernan Giraudo" -storepass 0n3sp4n
	keytool -v -list -keystore $archivo_keystore -storepass 0n3sp4n # ver el contenido generado
  else
    echo "El archivo '$archivo_keystore' ya existe. No se genera uno nuevo."
  fi	
 }
 
# ejecutar_apkid (apk_dir)
#
ejecutar_apkid() {
  apk_dir=$1
  output_dir=$apk_dir/07_apkid
  mkdir -p $output_dir
  # Iterar sobre cada archivo en el directorio
  for archivo_apk in "$apk_dir"/*.apk; do
	if [ -f "$archivo_apk" ]; then
	  filename=$(basename "$archivo_apk")
	  output_file=$output_dir/$filename.log
	  echo Generando $output_file
	  # Ejecutar APKID y guardar salida
	  /home/hernan/rasp/tools/APKiD/docker/apkid.sh --verbose $archivo_apk > $output_file
      fi
	done
}
 
# decompilar_apktool (apk_dir)
#
decompilar_apktool() { 
  apk_dir=$1 
  decompiled_dir=$2
  mkdir -p $decompiled_dir
  # Iterar sobre cada archivo en el directorio
  for archivoAPK in "$apk_dir"/*.apk; do
    if [ -f "$archivoAPK" ]; then
	nombreArchivo=$(basename "$archivoAPK")
	nombreArchivoSinExtension="${nombreArchivo%.*}" 
	echo "apktool $archivoAPK -o $decompiled_dir/$nombreArchivoSinExtension" 
	run_apktool d $archivoAPK -o $decompiled_dir/$nombreArchivoSinExtension -f # Decompilar el archivo con APK tool
  fi
done
}

# decompilar_jadx (apk_dir)
#

decompilar_jadx() {
  apk_dir=$1 
  decompiled_dir=$2
  mkdir -p $decompiled_dir

# Iterar sobre cada archivo en el directorio
for archivoAPK in "$apk_dir"/*.apk; do
  if [ -f "$archivoAPK" ]; then
	nombreArchivo=$(basename "$archivoAPK")
	nombreArchivoSinExtension="${nombreArchivo%.*}" 
	echo $nombreArchivo 
	run_jadx --no-res $archivoAPK -d $decompiled_dir/$nombreArchivoSinExtension # Descompilar el archivo con JADX
  fi
done
}

decompilar_jadx_gui() {
  apk_dir=$1 

# Iterar sobre cada archivo en el directorio
for archivoAPK in "$apk_dir"/*.apk; do
  if [ -f "$archivoAPK" ]; then
	echo $archivoAPK 
	run_jadx_gui --deobf --no-res-resolve $archivoAPK # Descompilar el archivo con JADX GUI
  fi
done
}

apkleaks() {
  apk_dir=$1 
  output_dir=$2
  
echo apk_dir=$apk_dir
echo output_dir=$output_dir
# Verifica que el directorio exista
if [ ! -d "$apk_dir" ]; then
  echo "Error: el directorio '$apk_dir' no existe."
  exit 1
fi

mkdir -p $output_dir

# Ruta al entorno virtual y al script apkleaks
ENTORNO=~/rasp/tools/apkleaks/mi_entorno
APKLEAKS=~/rasp/tools/apkleaks/apkleaks.py

# Activar el entorno virtual
source "$ENTORNO/bin/activate"

# Procesar todos los archivos .apk en el directorio
for apk in "$apk_dir"/*.apk; do
  [ -e "$apk" ] || continue  # salta si no hay .apk

  chmod 777 $apk 
  nombre_base=$(basename "$apk" .apk)
  salida="$output_dir/${nombre_base}_results.json"

  echo "🔍 Analizando $apk..."
  python "$APKLEAKS" -f "$apk" -o "$salida" --json
done

# Desactivar el entorno virtual
deactivate

echo "✅ Análisis completo."

}
