#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "=========================================="
echo "  USE_CASE_7: Certificado Digital Español "
echo "  FNMT / ACCV / ANF — ENS ALTO            "
echo "=========================================="
echo ""

# 1. CAs españolas
echo "Paso 1/3: Descargando CAs españolas..."
bash certificates/spanish-cas/download-cas.sh
echo ""

# 2. Certificado TLS servidor
echo "Paso 2/3: Generando certificado TLS del servidor..."
if [ ! -f nginx/ssl/server.crt ]; then
    bash nginx/ssl/generate-certs.sh
else
    echo "  ✅ Ya existe nginx/ssl/server.crt, omitiendo."
fi
echo ""

# 3. Arranca servicios
echo "Paso 3/3: Arrancando servicios Docker..."
docker-compose up -d

echo ""
echo "⏳ Esperando a que Keycloak esté listo..."
for i in $(seq 1 30); do
    if curl -sf http://localhost:8082/health/ready > /dev/null 2>&1; then
        echo "✅ Keycloak listo."
        break
    fi
    printf "."
    sleep 5
done
echo ""

echo ""
echo "=========================================="
echo "  ✅ USE_CASE_7 en marcha"
echo ""
echo "  Portal Certificado → https://localhost:8443"
echo "  Keycloak Admin     → http://localhost:8082"
echo "                       admin / admin"
echo ""
echo "  Para usar:"
echo "  1. Abre https://localhost:8443 en el navegador"
echo "  2. Acepta el aviso de certificado auto-firmado"
echo "  3. Haz clic en 'Acceder con Certificado Digital'"
echo "  4. El navegador te pedirá seleccionar tu cert FNMT"
echo "=========================================="
