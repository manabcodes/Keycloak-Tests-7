# Configurar Autenticación con Google en Keycloak

Esta guía te ayudará a configurar el inicio de sesión con Google (Gmail) en Keycloak.

## Paso 1: Obtener Credenciales de Google OAuth

### 1.1. Crear un Proyecto en Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Inicia sesión con tu cuenta de Google
3. Crea un nuevo proyecto o selecciona uno existente
4. Anota el nombre del proyecto

### 1.2. Habilitar la API de Google+

1. En el menú lateral, ve a **APIs & Services** > **Library**
2. Busca "Google+ API" o "People API"
3. Haz clic en el resultado y luego en **Enable**

### 1.3. Configurar la Pantalla de Consentimiento OAuth

1. Ve a **APIs & Services** > **OAuth consent screen**
2. Selecciona **External** (para desarrollo) o **Internal** (solo para usuarios de tu organización)
3. Completa los campos requeridos:
   - **App name**: Nombre de tu aplicación (ej: "Empresa SSO")
   - **User support email**: Tu email
   - **Developer contact information**: Tu email
4. Haz clic en **Save and Continue**
5. En **Scopes**, haz clic en **Save and Continue** (los scopes por defecto son suficientes)
6. En **Test users**, agrega los emails de prueba si es necesario
7. Haz clic en **Save and Continue** y luego **Back to Dashboard**

### 1.4. Crear Credenciales OAuth 2.0

1. Ve a **APIs & Services** > **Credentials**
2. Haz clic en **Create Credentials** > **OAuth client ID**
3. Selecciona **Web application** como tipo de aplicación
4. Completa los campos:
   - **Name**: "Keycloak SSO" (o el nombre que prefieras)
   - **Authorized JavaScript origins**: 
     - `http://localhost:8080`
   - **Authorized redirect URIs**:
     - `http://localhost:8080/realms/empresa-realm/broker/google/endpoint`
5. Haz clic en **Create**
6. **IMPORTANTE**: Copia el **Client ID** y el **Client Secret** (solo se muestra una vez)

## Paso 2: Configurar Keycloak

### Opción A: Usando la Interfaz Web de Keycloak

1. Accede a la consola de administración de Keycloak:
   - URL: `http://localhost:8080`
   - Usuario: `admin`
   - Contraseña: `admin`

2. Selecciona el realm **empresa-realm**

3. En el menú lateral, ve a **Identity Providers**

4. Haz clic en **Add provider** y selecciona **Google**

5. Completa la configuración:
   - **Alias**: `google` (o déjalo por defecto)
   - **Client ID**: Pega el Client ID de Google
   - **Client Secret**: Pega el Client Secret de Google
   - **Default Scopes**: `openid profile email` (ya está configurado)

6. En la pestaña **Settings**:
   - **Trust Email**: Activa esta opción si quieres que Keycloak confíe en el email verificado de Google
   - **First Login Flow**: Selecciona "first broker login" (por defecto)
   - **Sync Mode**: Selecciona "import" para importar usuarios automáticamente

7. Haz clic en **Save**

8. **Habilita el proveedor**: Asegúrate de que el toggle **Enabled** esté activado

### Opción B: Actualizar el Archivo JSON del Realm

1. Edita el archivo `keycloak-config/realm-empresa.json`

2. Busca la sección `identityProviders` y actualiza:
   ```json
   "identityProviders": [
     {
       "alias": "google",
       "providerId": "google",
       "enabled": true,
       "config": {
         "clientId": "TU_GOOGLE_CLIENT_ID_AQUI",
         "clientSecret": "TU_GOOGLE_CLIENT_SECRET_AQUI",
         "defaultScope": "openid profile email"
       }
     }
   ]
   ```

3. Reinicia los servicios de Docker:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Paso 3: Probar el Login con Google

1. Abre una ventana de incógnito en tu navegador
2. Ve a una de tus aplicaciones:
   - `http://localhost:3000/portal`
   - `http://localhost:3000/proyectos`
   - `http://localhost:3000/admin`
3. Deberías ver un botón o enlace para iniciar sesión con Google
4. Haz clic en el botón de Google
5. Serás redirigido a la página de autenticación de Google
6. Inicia sesión con tu cuenta de Google
7. Acepta los permisos solicitados
8. Serás redirigido de vuelta a tu aplicación con la sesión iniciada

## Configuración de Roles para Usuarios de Google

Por defecto, los usuarios que se autentican con Google no tienen roles asignados. Puedes configurar esto de dos formas:

### Opción 1: Asignar Roles Manualmente

1. En Keycloak, ve a **Users**
2. Busca el usuario creado automáticamente (usualmente el email de Google)
3. Ve a la pestaña **Role Mappings**
4. Asigna los roles necesarios (user, manager, admin)

### Opción 2: Usar Mappers Automáticos (Avanzado)

Puedes configurar mappers en el Identity Provider para asignar roles automáticamente basándote en el dominio del email o atributos de Google.

## Agregar Otras Redes Sociales

Keycloak soporta múltiples proveedores de identidad:

- **GitHub**: Similar a Google, requiere Client ID y Client Secret
- **Facebook**: Requiere App ID y App Secret
- **Twitter**: Requiere API Key y API Secret
- **Microsoft/Azure AD**: Requiere Client ID y Client Secret
- **LinkedIn**: Requiere Client ID y Client Secret

El proceso es similar: obtener credenciales del proveedor y configurarlas en Keycloak.

## Solución de Problemas

### Error: "redirect_uri_mismatch"
- Verifica que la URI de redirección en Google Cloud Console coincida exactamente con:
  - `http://localhost:8080/realms/empresa-realm/broker/google/endpoint`

### Error: "invalid_client"
- Verifica que el Client ID y Client Secret sean correctos
- Asegúrate de que no haya espacios adicionales al copiar/pegar

### El botón de Google no aparece
- Verifica que el Identity Provider esté habilitado (`enabled: true`)
- Verifica que estés en el realm correcto (`empresa-realm`)
- Limpia la caché del navegador

### Usuario no se crea automáticamente
- Verifica que "Trust Email" esté activado
- Verifica que "Sync Mode" esté en "import"
- Revisa los logs de Keycloak para ver errores

## Notas Importantes

- En producción, usa HTTPS en lugar de HTTP
- Actualiza las URIs de redirección en Google Cloud Console para incluir tu dominio de producción
- Considera restringir el acceso por dominio de email usando "hostedDomain" en la configuración
- Los usuarios de Google se crean automáticamente en Keycloak la primera vez que inician sesión

