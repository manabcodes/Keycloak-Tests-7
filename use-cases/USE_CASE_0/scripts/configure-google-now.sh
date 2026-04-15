#!/bin/bash

# Script simplificado para configurar Google con las credenciales del archivo .env

set -e

# Cargar variables de entorno desde .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../../.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: No se encontró el archivo .env en ${ENV_FILE}"
    echo "Copia .env.example a .env y configura las credenciales"
    exit 1
fi

# Cargar variables del archivo .env
export $(grep -v '^#' "$ENV_FILE" | xargs)

# Usar variables de entorno o valores por defecto
CLIENT_ID="${GOOGLE_CLIENT_ID}"
CLIENT_SECRET="${GOOGLE_CLIENT_SECRET}"
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
REALM="empresa-realm"
ADMIN_USER="${KEYCLOAK_ADMIN_USER:-admin}"
ADMIN_PASS="${KEYCLOAK_ADMIN_PASS:-admin}"

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo "Error: GOOGLE_CLIENT_ID y GOOGLE_CLIENT_SECRET deben estar definidos en el archivo .env"
    exit 1
fi

echo "=========================================="
echo "  Configurando Google Identity Provider"
echo "=========================================="
echo ""

# Esperar a que Keycloak esté listo
echo "Esperando a que Keycloak esté disponible..."
for i in {1..30}; do
    if curl -s "${KEYCLOAK_URL}/realms/empresa-realm/.well-known/openid-configuration" > /dev/null 2>&1; then
        echo "✓ Keycloak está disponible"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Error: Keycloak no está disponible después de 30 intentos"
        echo "Verifica que los servicios estén corriendo: docker-compose ps"
        exit 1
    fi
    sleep 2
done

# Obtener token de administrador
echo "Obteniendo token de administrador..."
TOKEN_RESPONSE=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASS}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "None" ]; then
    echo "Error: No se pudo obtener el token de administrador"
    echo "Respuesta: $TOKEN_RESPONSE"
    exit 1
fi

echo "✓ Token obtenido"
echo ""

# Configuración del Identity Provider
IDP_CONFIG=$(cat <<EOF
{
  "alias": "google",
  "providerId": "google",
  "enabled": true,
  "updateProfileFirstLoginMode": "on",
  "trustEmail": true,
  "storeToken": false,
  "addReadTokenRoleOnCreate": false,
  "authenticateByDefault": false,
  "linkOnly": false,
  "firstBrokerLoginFlowAlias": "first broker login",
  "config": {
    "clientId": "${CLIENT_ID}",
    "clientSecret": "${CLIENT_SECRET}",
    "defaultScope": "openid profile email",
    "hostedDomain": "",
    "useJwksUrl": "true"
  }
}
EOF
)

# Verificar si el Identity Provider ya existe
echo "Verificando si el Identity Provider ya existe..."
EXISTING_IDP=$(curl -s -X GET \
  "${KEYCLOAK_URL}/admin/realms/${REALM}/identity-provider/instances/google" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" 2>/dev/null)

if echo "$EXISTING_IDP" | grep -q '"alias"'; then
    echo "Actualizando Identity Provider existente..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
      "${KEYCLOAK_URL}/admin/realms/${REALM}/identity-provider/instances/google" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "${IDP_CONFIG}")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Identity Provider actualizado correctamente"
    else
        echo "Error: No se pudo actualizar el Identity Provider (HTTP $HTTP_CODE)"
        echo "Respuesta: $(echo "$RESPONSE" | head -n-1)"
        exit 1
    fi
else
    echo "Creando nuevo Identity Provider..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
      "${KEYCLOAK_URL}/admin/realms/${REALM}/identity-provider/instances" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "${IDP_CONFIG}")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Identity Provider creado correctamente"
    else
        echo "Error: No se pudo crear el Identity Provider (HTTP $HTTP_CODE)"
        echo "Respuesta: $(echo "$RESPONSE" | head -n-1)"
        exit 1
    fi
fi

# Verificar la configuración
echo ""
echo "Verificando configuración..."
VERIFY=$(curl -s -X GET \
  "${KEYCLOAK_URL}/admin/realms/${REALM}/identity-provider/instances/google" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json")

if echo "$VERIFY" | grep -q '"enabled":true'; then
    echo "✓ Identity Provider de Google está HABILITADO"
else
    echo "⚠ Identity Provider no está habilitado"
fi

if echo "$VERIFY" | grep -q "$CLIENT_ID"; then
    echo "✓ Client ID configurado correctamente"
else
    echo "⚠ Client ID no encontrado en la configuración"
fi

echo ""
echo "=========================================="
echo "  ✅ Configuración completada"
echo "=========================================="
echo ""
echo "El Identity Provider de Google está configurado y habilitado."
echo ""
echo "Prueba el login con Google en:"
echo "  • http://localhost:3000/portal"
echo "  • http://localhost:3000/proyectos"
echo "  • http://localhost:3000/admin"
echo ""
echo "IMPORTANTE: Asegúrate de que en Google Cloud Console tengas configurada"
echo "la siguiente URI de redirección:"
echo "  http://localhost:8080/realms/empresa-realm/broker/google/endpoint"
echo ""

