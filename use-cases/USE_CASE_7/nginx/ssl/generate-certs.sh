#!/usr/bin/env bash
# Genera un certificado TLS auto-firmado para nginx (sólo para desarrollo)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔐 Generando certificado TLS del servidor nginx..."

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout server.key \
    -out server.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=Demo Dev/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

echo "✅ Generados: server.key y server.crt"
echo "   (válido 365 días, solo para entorno de desarrollo)"
