source utils/utils.bash

# ================== VALIDAR DATOS DE ENTRADA ==================

if [ -z "$1" ]; then
  echo "Uso: $0 <apk_dir>"
  exit 1
  fi
  
apk_dir="${1%/}" # Eliminar barra final si existe

if [ ! -d "$apk_dir" ]; then
  echo "El directorio '$apk_dir' no existe."
  exit 1
  fi

# ================== LOGICA PRINCIPAL ==================

echo
info "APKid $apk_dir"
echo Ejecuta apk_id
echo 

listar_apks $apk_dir

ejecutar_apkid $apk_dir

