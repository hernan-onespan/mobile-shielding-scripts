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
		apksigner.bat verify --print-certs $archivoAPK | grep certificate # Verificar certificado
		apksigner.bat verify -verbose $archivoAPK
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
 
# firmar (apk_dir keystore)
#
firmar_app() {
  apk_dir=$1
  archivo_keystore=$2
  echo archivo_keystore $archivo_keystore
  # Iterar sobre cada archivo en el directorio
  for archivo_apk in "$apk_dir"/*.apk; do
	if [ -f "$archivo_apk" ]; then
	  filename=$(basename "$archivo_apk")
      apksigner.bat sign --ks $archivo_keystore --ks-pass pass:0n3sp4n $archivo_apk
	  apksigner.bat verify --print-certs $archivo_apk | grep certificate # Verificar
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