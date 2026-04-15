# USE_CASE_7: Autenticacion con Certificado Digital Espanol (FNMT)

## Requisitos previos

- Docker Desktop instalado y en marcha
- Certificado FNMT instalado en el navegador (archivo `.p12` importado)
- El repositorio clonado o descomprimido en tu equipo

---

## Arranque

```bash
cd use-cases/USE_CASE_7

# Solo la primera vez:
bash certificates/spanish-cas/download-cas.sh
bash nginx/ssl/generate-certs.sh

# Siempre:
docker-compose up -d
```

Espera unos 20 segundos y abre **https://localhost:8443**

Acepta el aviso de certificado auto-firmado del navegador y haz clic en **Acceder con Certificado Digital**.

---

## Configuracion del flujo X.509 (solo la primera vez)

El realm se importa automaticamente pero el flujo de autenticacion necesita configurarse manualmente en la consola de Keycloak.

1. Abre **http://localhost:8082** y entra con `admin / admin`
2. Selecciona el realm **Portal Certificado Digital** (arriba a la izquierda)
3. Ve a **Authentication** en el menu izquierdo
4. Haz clic en **X.509 Browser Flow**
5. Haz clic en el engranaje junto a **X509/Validate Username Form**
6. Rellena los campos:
   - **Alias**: `x509-fnmt-config`
   - **User Identity Source**: `Match SubjectDN using regular expression`
   - **Regular Expression**: `SERIALNUMBER=IDCES-([^,]+)`
   - **User mapping method**: `Username or Email`
7. Guarda

---

## Anadir un nuevo usuario con certificado

Cada persona que quiera autenticarse necesita un usuario en Keycloak cuyo **username** sea su DNI o NIE (en minusculas).

1. Abre **http://localhost:8082** y entra con `admin / admin`
2. Selecciona el realm **Portal Certificado Digital**
3. Ve a **Users** y haz clic en **Add user**
4. Rellena:
   - **Username**: el DNI o NIE del usuario, por ejemplo `12345678a` o `z2171059w`
   - **First name** y **Last name**: nombre y apellidos
   - **Email**: opcional
5. Haz clic en **Create**
6. No hace falta asignar contrasena, el certificado es la autenticacion

El usuario puede entrar ahora en **https://localhost:8443** con su certificado FNMT instalado en el navegador.

---

## Como saber el username correcto para un certificado

El username tiene que coincidir exactamente con lo que extrae Keycloak del certificado. Para verlo, el usuario intenta entrar una vez y en los logs aparece:

```bash
docker-compose logs keycloak | grep "x509_cert_subject"
```

Busca el campo `SERIALNUMBER=IDCES-XXXXXXXXX`. El valor despues de `IDCES-` es el username, en minusculas.

---

## Parar los servicios

```bash
docker-compose down
```

Los datos (usuarios, configuracion) se conservan. Para borrar todo incluyendo la base de datos:

```bash
docker-compose down -v
```

---

## Puertos

| Servicio | URL |
|---|---|
| Portal | https://localhost:8443 |
| Keycloak Admin | http://localhost:8082 |
