#!/bin/bash

# Script para configurar Google como Identity Provider en Keycloak
# Este script actualiza el archivo realm-empresa.json con las credenciales de Google

set -e

REALM_FILE="keycloak-config/realm-empresa.json"
TEMP_FILE=$(mktemp)

echo "=========================================="
echo "  Configurar Google Identity Provider"
echo "=========================================="
echo ""

# Verificar que el archivo existe
if [ ! -f "$REALM_FILE" ]; then
    echo "Error: No se encuentra el archivo $REALM_FILE"
    exit 1
fi

# Solicitar credenciales
echo "Por favor, ingresa las credenciales de Google OAuth:"
echo ""
read -p "Client ID de Google: " CLIENT_ID
read -sp "Client Secret de Google: " CLIENT_SECRET
echo ""
echo ""

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo "Error: Client ID y Client Secret son requeridos"
    exit 1
fi

# Hacer backup del archivo original
cp "$REALM_FILE" "${REALM_FILE}.backup"
echo "✓ Backup creado: ${REALM_FILE}.backup"

# Actualizar el archivo JSON
# Usar Python para actualizar el JSON de forma segura
python3 << EOF
import json
import sys

try:
    with open('$REALM_FILE', 'r', encoding='utf-8') as f:
        realm = json.load(f)
    
    # Buscar el identity provider de Google
    if 'identityProviders' in realm and len(realm['identityProviders']) > 0:
        for idp in realm['identityProviders']:
            if idp.get('alias') == 'google' or idp.get('providerId') == 'google':
                idp['config']['clientId'] = '$CLIENT_ID'
                idp['config']['clientSecret'] = '$CLIENT_SECRET'
                idp['enabled'] = True
                print("✓ Identity Provider de Google actualizado")
                break
        else:
            print("Error: No se encontró el Identity Provider de Google en el archivo")
            sys.exit(1)
    else:
        print("Error: No se encontró la sección identityProviders en el archivo")
        sys.exit(1)
    
    # Guardar el archivo actualizado
    with open('$REALM_FILE', 'w', encoding='utf-8') as f:
        json.dump(realm, f, indent=2, ensure_ascii=False)
    
    print("✓ Archivo $REALM_FILE actualizado correctamente")
    
except Exception as e:
    print(f"Error al procesar el archivo JSON: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "  ✅ Configuración completada"
    echo "=========================================="
    echo ""
    echo "Próximos pasos:"
    echo "1. Reinicia los servicios de Docker:"
    echo "   docker-compose down"
    echo "   docker-compose up -d"
    echo ""
    echo "2. Espera a que Keycloak inicie completamente (30-60 segundos)"
    echo ""
    echo "3. Prueba el login con Google en:"
    echo "   http://localhost:3000/portal"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "  ❌ Error en la configuración"
    echo "=========================================="
    echo ""
    echo "Se restauró el backup del archivo original"
    exit 1
fi

