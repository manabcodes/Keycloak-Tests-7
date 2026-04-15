#!/usr/bin/env python3
import requests
import json
import os
import sys

# Cargar variables de entorno desde .env
env_file = os.path.join(os.path.dirname(__file__), '../../../.env')
if os.path.exists(env_file):
    with open(env_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value

# For USE_CASE_1, always use port 8081
KEYCLOAK_URL = 'http://localhost:8081'
REALM = 'unified-realm'
ADMIN_USER = os.environ.get('KEYCLOAK_ADMIN_USER', 'admin')
ADMIN_PASS = os.environ.get('KEYCLOAK_ADMIN_PASS', 'admin')
CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID')
CLIENT_SECRET = os.environ.get('GOOGLE_CLIENT_SECRET')

if not CLIENT_ID or not CLIENT_SECRET:
    print("Error: GOOGLE_CLIENT_ID y GOOGLE_CLIENT_SECRET deben estar definidos en .env")
    sys.exit(1)

# Obtener token
print("Obteniendo token de administrador...")
token_response = requests.post(
    f"{KEYCLOAK_URL}/realms/master/protocol/openid-connect/token",
    data={
        "username": ADMIN_USER,
        "password": ADMIN_PASS,
        "grant_type": "password",
        "client_id": "admin-cli"
    }
)

if token_response.status_code != 200:
    print(f"Error al obtener token: {token_response.status_code}")
    print(token_response.text)
    sys.exit(1)

access_token = token_response.json()['access_token']
print("✓ Token obtenido")

# Configuración del Identity Provider
idp_config = {
    "alias": "google",
    "providerId": "google",
    "enabled": True,
    "updateProfileFirstLoginMode": "on",
    "trustEmail": True,
    "storeToken": False,
    "addReadTokenRoleOnCreate": False,
    "authenticateByDefault": False,
    "linkOnly": False,
    "firstBrokerLoginFlowAlias": "first broker login",
    "config": {
        "clientId": CLIENT_ID,
        "clientSecret": CLIENT_SECRET,
        "defaultScope": "openid profile email",
        "hostedDomain": "",
        "useJwksUrl": "true"
    }
}

headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}

# Verificar si existe
print("Verificando si el Identity Provider existe...")
check_response = requests.get(
    f"{KEYCLOAK_URL}/admin/realms/{REALM}/identity-provider/instances/google",
    headers=headers
)

if check_response.status_code == 200:
    print("Actualizando Identity Provider existente...")
    response = requests.put(
        f"{KEYCLOAK_URL}/admin/realms/{REALM}/identity-provider/instances/google",
        headers=headers,
        json=idp_config
    )
    if response.status_code in [200, 204]:
        print("✓ Google Identity Provider actualizado correctamente")
    else:
        print(f"Error al actualizar: {response.status_code}")
        print(response.text)
        sys.exit(1)
else:
    print("Creando nuevo Identity Provider...")
    response = requests.post(
        f"{KEYCLOAK_URL}/admin/realms/{REALM}/identity-provider/instances",
        headers=headers,
        json=idp_config
    )
    if response.status_code in [200, 201]:
        print("✓ Google Identity Provider creado correctamente")
    else:
        print(f"Error al crear: {response.status_code}")
        print(response.text)
        sys.exit(1)

print("\n✅ Configuración completada")
print(f"\nPrueba el login con Google en:")
print(f"  http://localhost:3001/portal/")
print(f"  http://localhost:3001/proyectos/")
print(f"  http://localhost:3001/admin/")
print(f"  http://localhost:3001/cliente/")

