#!/bin/bash

source utils/utils.bash

# ================== LÓGICA PRINCIPAL ==================

echo
info "Repackaging Test"
echo Firma la app con un certificado distinto y la vuelve a instalar
echo 

# ================== VALIDAR DATOS DE ENTRADA ==================

if [ -z "$1" ]; then
  echo "Uso: $0 <apk_dir>"
  exit 1
  fi

DIR_PREFIX="${1%/}" # Eliminar barra final si existe

# Buscar todos los directorios que coincidan
#MATCHED_DIRS=($(find . -maxdepth 1 -type d -name "*${DIR_PREFIX}*" | sed 's|^\./||'))
MATCHED_DIRS=($(find . -maxdepth 1 -type d -name "*${DIR_PREFIX}*" | awk -F'./' '{print $2}'))

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

for apk_dir in "${MATCHED_DIRS[@]}"; do
    read -p "¿Procesar '$apk_dir'? (s/N): " RESP
    if [[ "$RESP" =~ ^[sS]$ ]]; then

        if [ ! -d "$apk_dir" ]; then
            echo "El directorio '$apk_dir' no existe (¿se eliminó?)."
            continue
        fi
		
		desinstalar_app "$apk_dir"

		listar_apks "$apk_dir"

		repackaged_apk_dir=$apk_dir/03_repackaged
		echo trace $apk_dir

		# Crear una copia de los apks originales
		mkdir -p $repackaged_apk_dir # -p: no falla si el directorio ya existe
		cp $apk_dir/*.apk $repackaged_apk_dir
		echo trace 1 $apk_dir

		firmar_app $repackaged_apk_dir $archivo_keystore
		echo trace 2 $apk_dir

		instalar_app $repackaged_apk_dir
		echo trace 3 $apk_dir
		
		ejecutar_app $apk_dir
		
		rm -r $repackaged_apk_dir
    fi
done

