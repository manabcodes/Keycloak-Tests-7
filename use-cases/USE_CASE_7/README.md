# USE_CASE_7: Autenticación con Certificado Digital Español (FNMT)

## Descripción

Este caso de uso demuestra autenticación mediante **certificados electrónicos españoles** emitidos por:
- **FNMT-RCM** (Fábrica Nacional de Moneda y Timbre) — el más común
- **ANF**, **Camerfirma**, **ACCV**, **CATCERT**

El ciudadano instala su certificado `.p12` / `.pfx` en el navegador y se autentica sin usuario/contraseña. Keycloak valida el certificado contra las CAs españolas y extrae el DNI/NIE automáticamente.

**Nivel de seguridad:** ENS ALTO  
**Protocolo:** X.509 / TLS mutual authentication

---

## Estructura de directorios

```
USE_CASE_7/
├── README.md
├── docker-compose.yml
├── nginx/
│   ├── nginx.conf
│   └── ssl/
│       └── generate-certs.sh        # Genera servidor TLS + CA auto-firmada
├── certificates/
│   └── spanish-cas/
│       └── download-cas.sh          # Descarga CAs reales de FNMT, ACCV, etc.
├── keycloak-config/
│   └── realm-certificate-auth.json  # Realm con X.509 Auth Flow
├── apps/
│   └── portal-certificado.html      # Portal de acceso con certificado
└── scripts/
    └── setup.sh                     # Script de arranque completo
```

---

## Requisitos previos

1. **Docker** y **Docker Compose** instalados
2. **Certificado FNMT instalado en el navegador** (`.p12` importado en Firefox/Chrome)
3. El certificado debe contener el DNI/NIE en el campo `serialNumber` del Subject

### Estructura del certificado FNMT (para referencia)

```
Subject:
  serialNumber = IDCES-12345678A   ← DNI (o IDCES-Z2171059W para NIE)
  CN           = APELLIDO1 APELLIDO2 NOMBRE
  givenName    = NOMBRE
  surname      = APELLIDO1 APELLIDO2
  C            = ES
  O            = FNMT-RCM

Issuer:
  CN = AC FNMT Usuarios
  O  = FNMT-RCM
  C  = ES
```

---

## Inicio rápido

```bash
cd use-cases/USE_CASE_7

# 1. Descarga las CAs españolas reales
./certificates/spanish-cas/download-cas.sh

# 2. Genera los certificados TLS del servidor nginx
./nginx/ssl/generate-certs.sh

# 3. Arranca todos los servicios
docker-compose up -d

# 4. Espera a que Keycloak esté listo (~60s) y accede a:
#    https://localhost:8443   → Portal de certificado
#    http://localhost:8082    → Keycloak Admin (admin/admin)
```

> **Nota:** El navegador mostrará aviso de certificado auto-firmado.  
> Acepta la excepción en `https://localhost:8443` antes de continuar.

---

## Cómo funciona el flujo

```
Browser                     Nginx                    Keycloak
  │                           │                          │
  │── GET https://localhost ──►│                          │
  │◄── TLS Handshake ─────────│                          │
  │── [Seleccionar Certificado]│                          │
  │── Client Certificate ─────►│                          │
  │                           │── validate cert chain ──►│
  │                           │   (contra CAs españolas) │
  │                           │◄── 200 OK + cert header ─│
  │                           │── forward cert header ───►│
  │                           │                     extract serialNumber
  │                           │                     lookup/create user
  │◄── redirect + JWT token ──────────────────────────────│
```

Nginx actúa como terminador TLS con autenticación de cliente (`ssl_verify_client optional`), extrae el certificado y lo pasa a Keycloak como header `ssl-client-cert`. Keycloak usa el **X.509 Authentication Flow** para validar y extraer la identidad.

---

## Configuración de Keycloak (resumen)

El realm `certificado-realm` incluye:

| Componente | Valor |
|---|---|
| Authentication Flow | `X.509 Browser Flow` |
| Identity source | `Match SubjectDN using regular expression` |
| Regex extracción DNI | `serialNumber=IDCES-([^,]+)` |
| User attribute mapeado | `username` |
| Certificados de confianza | CAs de FNMT, ACCV, ANF, Camerfirma |

---

## Verificación

```bash
# Ver logs de nginx (validación TLS)
docker-compose logs -f nginx

# Ver logs de Keycloak (autenticación X.509)
docker-compose logs -f keycloak | grep -i "x509\|cert\|serial"

# Listar usuarios creados automáticamente
curl -s http://localhost:8082/admin/realms/certificado-realm/users \
  -H "Authorization: Bearer $(./scripts/get-admin-token.sh)" | python3 -m json.tool
```
