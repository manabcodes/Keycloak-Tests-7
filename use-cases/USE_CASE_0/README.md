# USE_CASE_0: SSO con Realms Separados (Caso Anterior)

## Descripción

Este es el caso de uso **anterior** que implementaba SSO con **realms completamente separados**:
- `empresa-realm`: Para aplicaciones corporativas
- `cliente-realm`: Para aplicaciones de ciudadano

**Nota**: Este caso fue movido a USE_CASE_0 cuando se creó el nuevo USE_CASE_1 que implementa un realm unificado donde un empleado puede actuar como ciudadano en la misma sesión.

## Diferencias con USE_CASE_1

| Aspecto | USE_CASE_0 (Este) | USE_CASE_1 (Nuevo) |
|---------|----------------|------------------|
| Realms | 2 realms separados | 1 realm unificado |
| Sesiones | Sesiones independientes | Sesión única compartida |
| Empleado como ciudadano | No permitido (realms separados) | Permitido (mismo realm) |
| SSO | Solo entre apps del mismo realm | Entre todas las apps |
| Riesgo de sesión dual | No aplica | ⚠️ Requiere mitigación |

## Cómo Ejecutar

```bash
cd use-cases/USE_CASE_0
docker-compose up -d
```

## Enlaces de Acceso

### Portal Principal
- **Portal de Aplicaciones**: http://localhost:3000
  - Página principal con enlaces a todas las aplicaciones

### Aplicaciones del Realm Empresa (empresa-realm)

| Aplicación | URL | Descripción |
|------------|-----|-------------|
| Portal de Empleados | http://localhost:3000/portal | Portal principal para empleados |
| Gestión de Proyectos | http://localhost:3000/proyectos | Aplicación de gestión de proyectos |
| Panel de Administración | http://localhost:3000/admin | Panel administrativo |

### Aplicaciones del Realm Cliente (cliente-realm)

| Aplicación | URL | Descripción |
|------------|-----|-------------|
| Aplicación Cliente | http://localhost:3000/cliente | Portal para clientes |

### Keycloak

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Keycloak Admin Console | http://localhost:8080 | Consola de administración de Keycloak |
| Realm Empresa - OpenID Config | http://localhost:8080/realms/empresa-realm/.well-known/openid-configuration | Configuración OpenID del realm empresa |
| Realm Cliente - OpenID Config | http://localhost:8080/realms/cliente-realm/.well-known/openid-configuration | Configuración OpenID del realm cliente |

**Credenciales de Keycloak Admin**:
- Usuario: `admin`
- Contraseña: `admin`

## Usuarios de Prueba

### empresa-realm
| Usuario | Contraseña | Roles | Descripción |
|---------|------------|-------|-------------|
| `juan.empleado` | `empleado123` | empleado | Empleado regular |
| `maria.gerente` | `gerente123` | empleado, manager | Gerente |
| `carlos.admin` | `admin123` | empleado, manager, admin | Administrador |

### cliente-realm
| Usuario | Contraseña | Roles | Descripción |
|---------|------------|-------|-------------|
| `ana.cliente` | `cliente123` | cliente | Cliente regular |
| `luis.premium` | `premium123` | cliente, premium | Cliente premium |
| `sofia.vip` | `vip123` | cliente, premium, vip | Cliente VIP |

**Nota**: Los usuarios de un realm NO pueden acceder a aplicaciones de otro realm. Cada realm es completamente independiente.

## Referencias

- Ver [USE_CASE_1](../USE_CASE_1/README.md) para el nuevo caso de uso con realm unificado
- Ver [USE_CASES.md](../../USE_CASES.md) para la documentación principal
