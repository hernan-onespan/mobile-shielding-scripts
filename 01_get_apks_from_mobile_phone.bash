#!/bin/bash

# Este script busca paquetes instalados en un dispositivo Android conectado vía ADB,
# según un patrón dado como argumento. Para cada paquete encontrado:
# - Obtiene las rutas de los APKs asociados usando `adb shell pm path`.
# - Descarga todos los APKs a una carpeta local que se llama igual que el paquete.

# Verificar si se pasó un argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <patron-de-busqueda>"
  exit 1
fi

pattern="$1"

# Buscar paquetes que coincidan con el patrón
packages=$(adb shell pm list packages | grep "$pattern" | sed 's/package://')

# Verificar si se encontró al menos un paquete
if [ -z "$packages" ]; then
  echo "No se encontraron paquetes que coincidan con: $pattern"
  exit 1
fi

# Procesar cada paquete encontrado
for package in $packages; do
  read -p "¿Deseás procesar el paquete '$package'? [s/N]: " confirm
  case "$confirm" in
    [sS]|[sS][iI])
      echo "Procesando paquete: $package"
      mkdir -p "$package"

      # Obtener rutas de APKs para el paquete
      apk_paths=$(adb shell pm path "$package" | sed 's/^package://')

      for path in $apk_paths; do
	  
        # Obtener nombre de archivo (ej: base.apk)
        filename=$(basename "$path")

        # Construir nombre de archivo destino
        dest="$package/$filename"

        echo "Descargando $path a $dest"
        adb pull "$path" "$dest"
		
      done
      ;;
    *)
      echo "Omitiendo paquete: $package"
      ;;
  esac
done

echo "Descarga completa."
