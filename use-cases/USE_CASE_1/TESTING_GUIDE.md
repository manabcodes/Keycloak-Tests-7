# Testing Guide - USE_CASE_1

## Verificación Inicial

Antes de probar, verifica que los servicios estén corriendo:

```bash
cd use-cases/USE_CASE_1
docker-compose ps
```

Debes ver 3 contenedores corriendo:
- `keycloak-postgres-casouso1` (healthy)
- `keycloak-server-casouso1` (up)
- `keycloak-demo-app-casouso1` (up)

## Paso 1: Acceder al Portal Principal

1. Abre tu navegador
2. Ve a: **http://localhost:3001**
3. Deberías ver el portal principal con información sobre el realm unificado

## Paso 2: Probar Login como Empleado

1. Haz clic en **"Portal de Empleados"** o ve directamente a: **http://localhost:3001/portal/**
2. Serás redirigido a Keycloak para autenticarte
3. Usa las credenciales:
   - **Usuario**: `juan.empleado`
   - **Contraseña**: `empleado123`
4. Después del login, deberías ver el portal de empleados con tu información

## Paso 3: Probar SSO (Single Sign-On)

Una vez autenticado en el Portal de Empleados:

1. En la misma sesión del navegador, abre una nueva pestaña
2. Ve a: **http://localhost:3001/proyectos/**
3. **NO deberías tener que autenticarte de nuevo** - esto es SSO funcionando
4. Deberías acceder directamente a la aplicación de Gestión de Proyectos

## Paso 4: Probar como Ciudadano

1. **Cierra la sesión** del empleado (botón "Cerrar Sesión")
2. Ve a: **http://localhost:3001/cliente/**
3. Serás redirigido a Keycloak
4. Usa las credenciales:
   - **Usuario**: `pedro.ciudadano`
   - **Contraseña**: `ciudadano123`
5. Deberías acceder a la aplicación cliente

## Paso 5: Probar el Caso Especial (Empleado + Ciudadano)

Este es el caso de riesgo documentado:

1. **Cierra la sesión** actual
2. Ve a: **http://localhost:3001/portal/**
3. Usa las credenciales:
   - **Usuario**: `ana.empleado.ciudadano`
   - **Contraseña**: `empleado123`
4. Verifica que tienes los roles: `empleado` y `ciudadano`
5. Ahora, **sin cerrar sesión**, abre una nueva pestaña
6. Ve a: **http://localhost:3001/cliente/**
7. **NO deberías tener que autenticarte** (SSO unificado)
8. Deberías poder acceder a la aplicación cliente con el mismo usuario

## Usuarios de Prueba Disponibles

| Usuario | Contraseña | Roles | Descripción |
|---------|------------|-------|-------------|
| `juan.empleado` | `empleado123` | empleado | Solo empleado |
| `maria.gerente` | `gerente123` | empleado, manager | Gerente |
| `carlos.admin` | `admin123` | empleado, manager, admin | Administrador |
| `pedro.ciudadano` | `ciudadano123` | ciudadano | Solo ciudadano |
| `ana.empleado.ciudadano` | `empleado123` | empleado, ciudadano | **Empleado + Ciudadano** ⚠️ |

## URLs Importantes

- **Portal Principal**: http://localhost:3001
- **Portal de Empleados**: http://localhost:3001/portal/
- **Gestión de Proyectos**: http://localhost:3001/proyectos/
- **Panel de Administración**: http://localhost:3001/admin/
- **Aplicación Cliente**: http://localhost:3001/cliente/
- **Keycloak Admin**: http://localhost:8081 (admin/admin)

## Solución de Problemas

### Error: "No puedo acceder a localhost:3001"

**Solución**:
1. Verifica que el contenedor esté corriendo: `docker-compose ps`
2. Si no está corriendo: `docker-compose up -d`
3. Espera unos segundos y vuelve a intentar

### Error: "redirect_uri_mismatch"

**Solución**:
1. Asegúrate de usar exactamente: `http://localhost:3001` (no `localhost:3001` sin http)
2. Verifica que el puerto sea `3001` (no `3000`)

### Error: "Invalid credentials"

**Solución**:
1. Verifica que estés usando las credenciales correctas de la tabla arriba
2. Asegúrate de que el realm `unified-realm` se haya importado correctamente
3. Puedes verificar en Keycloak Admin: http://localhost:8081

### No funciona el SSO

**Solución**:
1. Asegúrate de estar usando el mismo navegador y no haber cerrado sesión
2. Verifica que ambas aplicaciones usen el mismo realm (`unified-realm`)
3. Limpia las cookies del navegador y vuelve a intentar

### Keycloak no responde

**Solución**:
1. Verifica los logs: `docker-compose logs keycloak`
2. Reinicia Keycloak: `docker-compose restart keycloak`
3. Si persiste, reinicia todo: `docker-compose down && docker-compose up -d`

## Verificar que Todo Funciona

Ejecuta este comando para verificar que todo está bien:

```bash
cd use-cases/USE_CASE_1
echo "=== Verificación ===" && \
echo "Keycloak:" && curl -s -o /dev/null -w "  %{http_code}\n" http://localhost:8081/realms/unified-realm/.well-known/openid-configuration && \
echo "Portal:" && curl -s -o /dev/null -w "  %{http_code}\n" http://localhost:3001/ && \
echo "Portal Empleados:" && curl -s -o /dev/null -w "  %{http_code}\n" http://localhost:3001/portal/ && \
echo "Aplicación Cliente:" && curl -s -o /dev/null -w "  %{http_code}\n" http://localhost:3001/cliente/
```

Todos deberían devolver `200`.

