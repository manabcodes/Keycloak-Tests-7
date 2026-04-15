#!/bin/bash

# Script para configurar Google Identity Provider usando la API de Keycloak
# Útil cuando Keycloak ya está corriendo y no quieres reiniciar

set -e

KEYCLOAK_URL="http://localhost:8080"
REALM="empresa-realm"
ADMIN_USER="admin"
ADMIN_PASS="admin"

echo "=========================================="
echo "  Configurar Google via API de Keycloak"
echo "=========================================="
echo ""

# Verificar que Keycloak esté corriendo
if ! curl -s "${KEYCLOAK_URL}/health/ready" > /dev/null 2>&1; then
    echo "Error: Keycloak no está disponible en ${KEYCLOAK_URL}"
    echo "Asegúrate de que los servicios de Docker estén corriendo"
    exit 1
fi

# Obtener token de administrador
echo "Obteniendo token de administrador..."
TOKEN_RESPONSE=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASS}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli")

ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: No se pudo obtener el token de administrador"
    exit 1
fi

echo "✓ Token obtenido"
echo ""

# Solicitar credenciales
read -p "Client ID de Google: " CLIENT_ID
read -sp "Client Secret de Google: " CLIENT_SECRET
echo ""
echo ""

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo "Error: Client ID y Client Secret son requeridos"
    exit 1
fi

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
EXISTING_IDP=$(curl -s -X GET \
  "${KEYCLOAK_URL}/admin/realms/${REALM}/identity-provider/instances/google" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" 2>/dev/null)

if echo "$EXISTING_IDP" | grep -q "alias"; then
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
        echo "$RESPONSE" | head -n-1
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
        echo "$RESPONSE" | head -n-1
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "  ✅ Configuración completada"
echo "=========================================="
echo ""
echo "El Identity Provider de Google está ahora habilitado."
echo ""
echo "Prueba el login con Google en:"
echo "  http://localhost:3000/portal"
echo "  http://localhost:3000/proyectos"
echo "  http://localhost:3000/admin"
echo ""

