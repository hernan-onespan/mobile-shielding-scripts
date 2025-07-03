#!/bin/bash

# ================== CONFIGURACIÓN ==================
source "$(dirname "$0")/utils/config.env"
source "$(dirname "$0")/utils/utils.bash"
archivo_debug=utils/requests.debug
# ===================================================


# =========================================
# obtener_bearer_token
# Obtiene el bearer token de autenticación
# =========================================
obtener_bearer_token() {
  local auth_header
  auth_header=$(echo -n "$clientid:$clientsecret" | base64 -w0)

  local request
  request=$(echo "curl --silent --location 'https://auth.mobile.onespan.com/oauth2/token' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --header \"Authorization: Basic $auth_header\" \
    --data-urlencode 'grant_type=client_credentials'
	") 
  	
  local response
  response=$(eval "$request")

  echo "[obtener_bearer_token()] [request] $request" >> $archivo_debug
  echo "[obtener_bearer_token()] [response] $response" >> $archivo_debug

  local token
  token=$(echo "$response" | jq -r '.access_token')

  echo "[obtener_bearer_token()] token=$token" >> $archivo_debug

  if [ "$token" != "null" ] && [ -n "$token" ]; then
    echo "$token"
  else
    error "Error al obtener token. Respuesta: $response"
    exit 1
  fi
}

# =========================================
# enviar_a_appshielding (archivo, token, directorio)
# Envia un APK a OneSpan App Shielding y maneja el flujo completo
# =========================================
enviar_a_appshielding() {
  local archivo="$1"
  local token="$2"
  local directorio="$3"
  local ubicacionArchivo=$3\\$1

  info "Enviando archivo '$ubicacionArchivo' a la API..."

  # Obtener URL para subir el archivo
  local url_request
  url_request=$(echo "curl --silent --location 'https://api-appshielding.mobile.onespan.com/v1/shieldingapps' \
    --header \"Content-Type: application/json\" \
    --header \"Authorization: Bearer $token\" \
    --data '{
      \"configurationKey\": \"$configurationKey\",
      \"shielderPlatform\": \"ANDROID\",
      \"fileNameWithExt\": \"$archivo\"
    }' 
	")

  local response
  url_response=$(eval "$url_request")

  echo "[enviar_a_appshielding()] [url_request] $url_request" >> $archivo_debug
  echo "[enviar_a_appshielding()] [url_response] $url_response" >> $archivo_debug

  # Extraer la URL del JSON de respuesta
  local url
  url=$(echo "$url_response" | jq -r '.url')
  local=uuid
  uuid=$(echo "$url_response" | jq -r '.uuid')

  echo "[enviar_a_appshielding()] url=$url" >> $archivo_debug
  echo "[enviar_a_appshielding()] uuid=$uuid" >> $archivo_debug
  titulo "uuid=$uuid" 
  
  if [ "$url" == "null" ] || [ -z "$url" ]; then
    echo "Error: No se obtuvo la URL de respuesta. Respuesta completa:" >&2
    echo "$response" >&2
    exit 1
  fi

  # Realizar el PUT enviando el archivo en formato binario
  echo " "
  echo "Subiendo archivo '$ubicacionArchivo' en formato binario..."
  
  put_response=$(mktemp)
  put_request=$(echo "curl -s -w \"%{http_code}\" -o \"$put_response\" --location --request PUT \"$url\" \
	--header "Authorization: Bearer $token" \
	--data-binary '@$ubicacionArchivo'
	")
  
  put_status=$(eval "$put_request")

  echo "[enviar_a_appshielding()] [put_request] $put_request" >> $archivo_debug
  echo "[enviar_a_appshielding()] [put_status] $put_status" >> $archivo_debug
  echo "[enviar_a_appshielding()] [put_response] " >> $archivo_debug
  cat $put_response >> $archivo_debug # no imprime nada
 
# Mostrar mensaje con color según el código de estado
  if [ "$put_status" == "200000000" ]; then
    echo -e "Status: ${GREEN}200 (OK)${NC}"
  elif [[ "$put_status" =~ ^4|^5 ]]; then
    echo -e "Status del PUT para '$ubicacionArchivo': ${RED}$put_status${NC}"
  else
    echo -e "Status del PUT para '$ubicacionArchivo': ${YELLOW}$put_status${NC}"
  fi 
 
# Imprimir solo si la respuesta no está vacía
  if [ -s "$put_response" ]; then
    echo "Respuesta del PUT:"
    cat "$put_response"
    echo ""
  fi
  rm "$put_response"
  
  # Iniciar proceso de blindaje con el uuid
  shield_response=$(mktemp)
  local shield_request
  shield_request=$(echo "curl -s -w \"%{http_code}\" -o \"$shield_response\" --location \
		--request POST \"https://api-appshielding.mobile.onespan.com/v1/shieldingapps?uuid=$uuid\" \
		--header \"Authorization: Bearer $token\" \
		--header \"Content-Type: application/json\" \
		--data '{
			\"configurationKey\": \"$configurationKey\",
			\"fileNameWithExt\": \"$archivo\"
			}'
	")
	
  shield_status=$(eval "$shield_request")

  echo "[enviar_a_appshielding()] [shield_request] $shield_request" >> $archivo_debug
  echo "[enviar_a_appshielding()] [shield_status] $shield_status" >> $archivo_debug
  echo "[enviar_a_appshielding()] [shield_response] " >> $archivo_debug
  cat $shield_response >> $archivo_debug
	    
  local=shield_uuid # Tiene que ser igual a la anterior
  shield_uuid=$(cat "$shield_response" | jq -r '.uuid')
  			
  echo " "
  # Mostrar resultado del blindaje
  if [ "$shield_status" == "200" ]; then
    printf "Blindaje iniciado para '%s': ${GREEN}200 (OK)${NC}\n" "$ubicacionArchivo"
  elif [ "$shield_status" == "201" ]; then
    printf "Blindaje iniciado para '%s': ${GREEN}201 (Created)${NC}\n" "$ubicacionArchivo"
  else 
    printf "Blindaje iniciado para '%s': ${RED}%s${NC}\n" "$ubicacionArchivo" "$shield_status"
  fi

  rm "$shield_response"
  

echo "Esperando a que el blindaje finalice..."

max_retries=60
sleep_seconds=10
attempt=0

while [ $attempt -lt $max_retries ]; do
  ((attempt++))

  local progress_request
  progress_request=$(echo "curl -s --location \"https://api-appshielding.mobile.onespan.com/v1/shieldingapps?uuid=$uuid&action=progress\" \
    --header \"Authorization: Bearer $token\" \
	")
  
  local progress_response
  progress_response=$(eval "$progress_request")
    
  progress_status=$(echo "$progress_response" | jq -r '.shieldingStatus' )
  local progress_percent

  if [ "$progress_status" == "QUEUED" ]; then
	progress_percent=0
  elif [ "$progress_status" == "SUCCESS" ]; then
  	progress_percent=100
  else
    progress_percent=$(echo "$progress_response" | jq -r '.progressInPercent' )
  fi
 
  echo "progress_status=$progress_status ($progress_percent%)" 
  echo "[enviar_a_appshielding()] [progress_request] $progress_request" >> $archivo_debug
  echo "[enviar_a_appshielding()] [progress_response] $progress_response" >> $archivo_debug
  echo "[enviar_a_appshielding()] [progress_status] $progress_status" >> $archivo_debug
  
  if [ "$progress_status" == "FAILED" ]; then
    error "Blindaje falló."
  fi

  if [ "$progress_status" == "SUCCESS" ]; then
    echo " "
    echo -e "${GREEN}Blindaje completado exitosamente.${NC}"
	
	local download_url_request
	download_url_request=$(echo "curl -s --location \"https://api-appshielding.mobile.onespan.com/v1/shieldingapps?uuid=$uuid&action=download\" \
    --header \"Authorization: Bearer $token\" \
	")
	
	local download_url_response
	download_url_response=$(eval "$download_url_request")
	
    download_url=$(echo "$download_url_response" | jq -r '.url')

  echo "[enviar_a_appshielding()] [download_url_request] $download_url_request" >> $archivo_debug
  echo "[enviar_a_appshielding()] [download_url_response] $download_url_response" >> $archivo_debug
  echo "[enviar_a_appshielding()] [download_url] $download_url" >> $archivo_debug

  shielded_dir=$directorio/shielded
  mkdir -p $shielded_dir
    if [ -n "$download_url" ] && [ "$download_url" != "null" ]; then
	  output_name="$shielded_dir/${archivo%.*}.zip" # reemplaza .apk por .zip
      echo "Descargando APK blindado como $output_name..."
      curl -s -L -o "$output_name" "$download_url"
      echo -e "${GREEN}APK blindado guardado como '$output_name'.${NC}"
      # Descomprimir
      unzip -o -q $output_name -d $directorio/shielded # o: overwrite q: quiet
	  rm $shielded_dir/config.json
	  rm $shielded_dir/mapping.txt
	  rm $output_name
	else
      echo -e "${RED}Error: no se encontró downloadUrl en la respuesta.${NC}"
      exit 1
    fi
	
    break
  fi

  sleep $sleep_seconds
done

if [ "$progress_status" != "SUCCESS" ]; then
  echo -e "${RED}Timeout: el blindaje no finalizó luego de $((max_retries * sleep_seconds)) segundos.${NC}"
fi
  

  
}


# ================== VALIDAR DATOS DE ENTRADA ==================

titulo "\n-> Blindar una aplicacion por API"

# Verificar argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <nombre-del-directorio>"
  exit 1
fi

# Eliminar barra final si existe
packageName="${1%/}"

if [ ! -d "$packageName" ]; then
  echo "El directorio '$packageName' no existe."
  exit 1
fi

# ================== CERTIFICADO PARA FIRMAR APPS ==================

archivo_keystore="utils/keystore"

generar_certificado $archivo_keystore

# ================== LÓGICA PRINCIPAL ==================

info "\nObteniendo bearer token..."
bearertoken=$(obtener_bearer_token)
info "Token: $bearertoken"
echo "Archivos en '$packageName':"
ls -1 "$packageName"
echo " "

# Iterar sobre cada archivo en el directorio
for archivo in "$packageName"/*.apk; do
  if [ -f "$archivo" ]; then
    filename=$(basename "$archivo")
    enviar_a_appshielding "$filename" "$bearertoken" "$packageName"
  fi
done

shieldedApkDir="$packageName/shielded"

firmar_app "$shieldedApkDir" "$archivo_keystore"
		
desinstalar_app "$packageName"		
		
instalar_app "$shieldedApkDir"
		
ejecutar_app "$packageName"		
