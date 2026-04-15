# USE_CASE_1: Single Sign-On (SSO) en Aplicaciones Corporativas y Ciudadano

## Descripción

Este caso de uso implementa Single Sign-On (SSO) para aplicaciones corporativas y también para ciudadanos **en el mismo realm**. Un empleado puede actuar también como ciudadano en la misma sesión, lo cual requiere valorar los riesgos de seguridad asociados.

## Objetivos

- ✅ Permitir que usuarios corporativos accedan a múltiples aplicaciones con una sola autenticación
- ✅ Permitir que ciudadanos accedan a servicios públicos con una sola autenticación
- ✅ **Permitir que un empleado actúe como ciudadano en la misma sesión**
- ✅ **Implementar autenticación de dos factores (2FA) con TOTP para pruebas de seguridad**
- ⚠️ Gestionar y documentar los riesgos de seguridad de sesiones duales

## Arquitectura

### Realm Unificado

**unified-realm**: Realm único que contiene tanto aplicaciones corporativas como de ciudadano
- **Usuarios**: Pueden tener roles tanto de empleado como de ciudadano
- **Aplicaciones Corporativas**:
  - Portal de Empleados (`portal-empleados`)
  - Gestión de Proyectos (`proyectos-app`)
  - Panel de Administración (`panel-admin`)
- **Aplicaciones de Ciudadano**:
  - Aplicación Cliente (`cliente-app`)

### Roles Configurados

1. **Roles Corporativos**:
   - `empleado`: Usuario regular de la empresa
   - `manager`: Gerente con permisos de gestión
   - `admin`: Administrador del sistema

2. **Roles de Ciudadano**:
   - `ciudadano`: Usuario ciudadano con acceso a servicios públicos

3. **Roles Combinados**:
   - Un usuario puede tener tanto roles corporativos como de ciudadano simultáneamente

### Sesión Unificada

- **Una sola sesión**: Todos los usuarios se autentican en el mismo realm
- **SSO completo**: Una vez autenticado, el usuario puede acceder a todas las aplicaciones (corporativas y de ciudadano) sin re-autenticarse
- **Tokens compartidos**: El mismo access_token e id_token se usan para todas las aplicaciones

## Riesgos de Seguridad Identificados

### ⚠️ Riesgo 1: Conflicto de Roles

**Problema**: Un empleado con rol `admin` que también tiene rol `ciudadano` puede acceder a servicios ciudadanos con privilegios elevados.

**Mitigación**:
- Las aplicaciones deben validar roles específicos para cada contexto
- Implementar autorización a nivel de aplicación que ignore roles corporativos en contexto ciudadano
- Documentar claramente qué roles se usan en cada aplicación

### ⚠️ Riesgo 2: Acceso No Autorizado

**Problema**: Un empleado puede acceder accidentalmente a aplicaciones de ciudadano con su sesión corporativa.

**Mitigación**:
- Implementar controles de autorización estrictos en cada aplicación
- Usar scopes específicos para limitar acceso
- Considerar implementar consentimiento explícito para cambio de contexto

### ⚠️ Riesgo 3: Auditoría y Trazabilidad

**Problema**: Difícil distinguir si un empleado está actuando como empleado o como ciudadano en los logs.

**Mitigación**:
- Implementar logging detallado que incluya contexto de aplicación
- Usar atributos de usuario para marcar el contexto actual
- Mantener auditoría separada por tipo de aplicación

### ⚠️ Riesgo 4: Nivel ENS

**Problema**: El nivel de seguridad requerido puede ser diferente para aplicaciones corporativas vs. ciudadanas.

**Mitigación**:
- Evaluar nivel ENS requerido para cada tipo de aplicación
- Implementar políticas de sesión más estrictas si es necesario
- Considerar separación de realms si los niveles ENS son incompatibles

## Usuarios de Prueba

| Usuario | Contraseña | Roles | Descripción |
|---------|------------|-------|-------------|
| juan.empleado | empleado123 | empleado | Solo empleado |
| maria.gerente | gerente123 | empleado, manager | Gerente corporativo |
| carlos.admin | admin123 | empleado, manager, admin | Administrador |
| pedro.ciudadano | ciudadano123 | ciudadano | Solo ciudadano |
| ana.empleado.ciudadano | empleado123 | empleado, ciudadano | **Empleado que también es ciudadano** |

## Cómo Ejecutar

1. **Iniciar servicios**:
```bash
cd use-cases/USE_CASE_1
docker-compose up -d
```

2. **Acceder a las aplicaciones**:
   - Portal principal: http://localhost:3001
   - Portal de Empleados: http://localhost:3001/portal/
   - Gestión de Proyectos: http://localhost:3001/proyectos/
   - Panel de Administración: http://localhost:3001/admin/
   - Aplicación Cliente: http://localhost:3001/cliente/
   - Keycloak Admin: http://localhost:8081 (admin/admin)

## Flujo de SSO Unificado

1. Usuario accede a cualquier aplicación (ej: Portal de Empleados o Aplicación Cliente)
2. Si no está autenticado, es redirigido a Keycloak (unified-realm)
3. Usuario se autentica **una sola vez**
4. Keycloak emite tokens (access_token, id_token, refresh_token)
5. Usuario accede a la aplicación solicitada
6. **El usuario puede navegar a cualquier otra aplicación (corporativa o ciudadano) sin re-autenticarse**
7. Cada aplicación valida los roles necesarios del token

## Casos de Prueba

### Caso 1: Empleado accede a aplicación corporativa
1. Login como `juan.empleado`
2. Acceder a Portal de Empleados → ✅ Debe funcionar
3. Acceder a Gestión de Proyectos → ✅ Debe funcionar (SSO)
4. Acceder a Aplicación Cliente → ❌ Debe denegar (no tiene rol ciudadano)

### Caso 2: Ciudadano accede a aplicación de ciudadano
1. Login como `pedro.ciudadano`
2. Acceder a Aplicación Cliente → ✅ Debe funcionar
3. Acceder a Portal de Empleados → ❌ Debe denegar (no tiene rol empleado)

### Caso 3: Empleado que también es ciudadano (RIESGO)
1. Login como `ana.empleado.ciudadano`
2. Acceder a Portal de Empleados → ✅ Debe funcionar
3. Acceder a Aplicación Cliente → ✅ Debe funcionar (tiene ambos roles)
4. **Verificar que no haya conflictos de autorización**

### Caso 4: Autenticación de dos factores (2FA)
1. Habilitar 2FA para un usuario (ver sección "Autenticación de Dos Factores" abajo)
2. Login como usuario con 2FA habilitado
3. Después de ingresar usuario/contraseña, Keycloak pedirá configurar TOTP
4. Escanear código QR con app autenticadora (Google Authenticator, Authy, etc.)
5. Ingresar código de verificación
6. A partir de entonces, cada login requerirá código TOTP

## Autenticación de Dos Factores (2FA)

### Configuración del Realm

El realm `unified-realm` ya tiene habilitada la acción requerida `CONFIGURE_TOTP` en la configuración. Esto permite que los usuarios configuren 2FA cuando sea necesario.

### Habilitar 2FA para un Usuario

Tienes **tres opciones** para habilitar 2FA:

#### Opción 1: Desde el Panel de Keycloak (Recomendado para pruebas)

1. Accede al Admin Console: http://localhost:8081 (admin/admin)
2. Selecciona el realm `unified-realm`
3. Ve a **Users** → Busca el usuario
4. Abre el usuario → Pestaña **Credentials**
5. Haz clic en **Set up authenticator application**
6. El usuario deberá configurar TOTP en su próximo login

#### Opción 2: Usando el Script Python (Recomendado para automatización)

```bash
cd use-cases/USE_CASE_1/scripts
python3 enable-2fa-user.py <username>
```

Ejemplo:
```bash
python3 enable-2fa-user.py carlos.admin
```

Para enviar un email al usuario:
```bash
python3 enable-2fa-user.py carlos.admin --email
```

#### Opción 3: Hacer 2FA Obligatorio para Todos los Usuarios

1. Accede al Admin Console: http://localhost:8081
2. Selecciona el realm `unified-realm`
3. Ve a **Authentication** → **Required Actions**
4. Busca **Configure OTP** y haz clic en el menú (⋮)
5. Selecciona **Set as default action**
6. Esto hará que todos los usuarios nuevos deban configurar 2FA

### Flujo de Usuario con 2FA

1. **Primera vez (Configuración)**:
   - Usuario inicia sesión con usuario/contraseña
   - Keycloak muestra pantalla para configurar TOTP
   - Usuario escanea código QR con app autenticadora
   - Usuario ingresa código de verificación
   - 2FA queda configurado

2. **Logins posteriores**:
   - Usuario ingresa usuario/contraseña
   - Keycloak pide código TOTP
   - Usuario ingresa código de su app autenticadora
   - Acceso concedido

### Aplicaciones de Autenticación Recomendadas

- **Google Authenticator** (iOS/Android)
- **Microsoft Authenticator** (iOS/Android)
- **Authy** (iOS/Android/Desktop)
- **1Password** (iOS/Android/Desktop)

### Deshabilitar 2FA para un Usuario

1. Admin Console → Users → Seleccionar usuario
2. Pestaña **Credentials**
3. Buscar **OTP Credential** y hacer clic en **Remove**

## Próximos Pasos

- [ ] Implementar validación de roles específica por contexto en cada aplicación
- [ ] Crear políticas de autorización que separen contexto corporativo de ciudadano
- [ ] Implementar logging detallado con contexto de aplicación
- [ ] Evaluar nivel ENS requerido y ajustar políticas de sesión
- [ ] Crear guía de mejores prácticas para desarrolladores
- [ ] Implementar pruebas automatizadas para validar separación de contextos
- [ ] Documentar procedimientos de auditoría

## Referencias

- [Documentación de Keycloak - Realms](https://www.keycloak.org/docs/latest/server_admin/#_realms)
- [Documentación de Keycloak - SSO](https://www.keycloak.org/docs/latest/securing_apps/#_sso)
- [Documentación de Keycloak - Roles](https://www.keycloak.org/docs/latest/server_admin/#_roles)
- [Documentación de Keycloak - Two-Factor Authentication](https://www.keycloak.org/docs/latest/server_admin/#_otp)
- [Documentación de Keycloak - Required Actions](https://www.keycloak.org/docs/latest/server_admin/#_required_actions)
- [USE_CASES.md](../../USE_CASES.md) - Documento principal con todos los casos de uso
