# USE_CASE_2: Autenticacion de Maquina + Secrets Vault (Passbolt) + Keycloak

## Objetivo

Este caso muestra el flujo solicitado:

1. La aplicacion X obtiene secretos desde Passbolt.
2. Con esos secretos, la aplicacion X hace login tecnico en Keycloak (client credentials).
3. La aplicacion X consume recursos de la aplicacion Z.
4. La aplicacion Z valida el token contra Keycloak antes de responder.

## Arquitectura del ejemplo

- `passbolt-real` (puerto 8083): Instancia oficial de Passbolt para pruebas reales.
- `keycloak` (puerto 8082): Emite y valida tokens en el realm `machine-realm`.
- `app-x` (puerto 5003): Obtiene secretos de Passbolt y consume `app-z`.
- `app-z` (puerto 5002): API protegida por token de Keycloak.

## Flujo tecnico

1. `app-x` se autentica en Passbolt real con una cuenta de servicio y su clave GPG privada.
2. `app-x` lee desde Passbolt un recurso que contiene la configuracion de Keycloak y `app-z`.
3. `app-x` solicita `access_token` con `grant_type=client_credentials`.
4. `app-x` llama a `app-z` con `Authorization: Bearer <token>`.
5. `app-z` introspecciona el token en Keycloak y responde si esta activo.

> Nota: el ejemplo usa Passbolt real, pero la cuenta de servicio y el recurso compartido deben crearse una vez en la UI de Passbolt. App X necesita que se le pasen el fingerprint de la clave, la clave privada y el ID del recurso que contiene el secreto.

## Ejecucion

```bash
cd use-cases/USE_CASE_2
docker-compose up -d --build
```

## Bootstrap de Passbolt real

La demo de este repositorio ya queda cableada con una cuenta y recurso local de Passbolt para ejecucion inmediata. Si quieres regenerarlo desde cero, sigue estos pasos:

1. Arranca el stack.
2. Crea el primer administrador con el comando oficial de Passbolt dentro del contenedor:

```bash
docker compose exec passbolt-real su -m -c "/usr/share/php/passbolt/bin/cake passbolt register_user -u admin@example.com -f Admin -l Local -r admin" -s /bin/sh www-data
```

3. Completa el alta en el navegador en `http://localhost:8083`.
4. Crea un usuario de servicio para App X, importa su clave pública y comparte con ese usuario el recurso que contiene el JSON de configuracion.
5. Exporta la clave privada de ese usuario y define estas variables para `app-x`:

```bash
export PASSBOLT_SERVICE_KEY_ID="<fingerprint-de-la-clave>"
export PASSBOLT_PRIVATE_KEY_FILE="/ruta/a/private.key"
export PASSBOLT_PRIVATE_KEY_PASSPHRASE="<passphrase-si-aplica>"
export PASSBOLT_SECRET_RESOURCE_ID="<uuid-del-recurso-compartido>"
```

El secreto compartido puede usar esta forma:

```json
{
  "keycloak": {
    "client_id": "app-x-service",
    "client_secret": "app-x-secret-123",
    "token_url": "http://keycloak:8080/realms/machine-realm/protocol/openid-connect/token"
  },
  "app_z": {
    "base_url": "http://app-z:5002",
    "resource_path": "/secure-data"
  }
}
```

## Prueba end-to-end

```bash
curl http://localhost:5003/login-and-consume-z
```

Respuesta esperada (aproximada):

```json
{
  "flow": "passbolt-real -> keycloak -> app-z",
  "app_z_status_code": 200,
  "app_z_response": {
    "message": "Datos protegidos de la aplicacion Z",
    "authorized_client": "app-x-service",
    "scope": ""
  }
}
```

## Accesos utiles

- Keycloak Admin: `http://localhost:8082` (admin/admin)
- Passbolt real: `http://localhost:8083`
- Realm: `machine-realm`
- Token endpoint: `http://localhost:8082/realms/machine-realm/protocol/openid-connect/token`

## Notas de seguridad

- En este ejemplo se usa la API real de Passbolt para demostrar el patron tecnico.
- En produccion se debe usar TLS, rotacion de secretos y control de acceso estricto.
- No se deben hardcodear secretos en codigo ni en repositorio.
- Para mantener el entorno limpio, la clave privada local de la demo se almacena en `use-cases/USE_CASE_2/keys/`.
