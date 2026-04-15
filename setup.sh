#!/bin/bash

# Script de ayuda para configurar y probar Keycloak

set -e

echo "🚀 Keycloak Demo - Script de Configuración"
echo "=========================================="
echo ""

# Función para mostrar el menú
show_menu() {
    echo "Selecciona una opción:"
    echo "1) Iniciar configuración estándar (con PostgreSQL)"
    echo "2) Iniciar configuración de desarrollo (H2 en memoria)"
    echo "3) Iniciar configuración de producción"
    echo "4) Detener todos los servicios"
    echo "5) Ver logs de Keycloak"
    echo "6) Ver estado de los servicios"
    echo "7) Limpiar todo (detener y eliminar volúmenes)"
    echo "8) Importar realm manualmente"
    echo "9) Salir"
    echo ""
}

# Función para esperar a que Keycloak esté listo
wait_for_keycloak() {
    echo "⏳ Esperando a que Keycloak esté listo..."
    max_attempts=30
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f http://localhost:8080/health/ready > /dev/null 2>&1; then
            echo "✅ Keycloak está listo!"
            return 0
        fi
        attempt=$((attempt + 1))
        echo "   Intento $attempt/$max_attempts..."
        sleep 2
    done
    
    echo "❌ Keycloak no respondió después de $max_attempts intentos"
    return 1
}

# Función para importar realm
import_realm() {
    echo "📥 Importando realm 'demo'..."
    
    if [ ! -f "keycloak-config/realm-demo.json" ]; then
        echo "❌ Error: No se encontró el archivo keycloak-config/realm-demo.json"
        return 1
    fi
    
    # Intentar importar usando la API de Keycloak
    echo "   Usando la API de Keycloak..."
    
    # Primero obtener el token de acceso
    TOKEN=$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=admin" \
        -d "password=admin" \
        -d "grant_type=password" \
        -d "client_id=admin-cli" | jq -r '.access_token')
    
    if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
        echo "❌ Error: No se pudo obtener el token de acceso"
        echo "   Asegúrate de que Keycloak esté corriendo y las credenciales sean correctas"
        return 1
    fi
    
    # Importar el realm
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8080/admin/realms \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d @keycloak-config/realm-demo.json)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" == "201" ]; then
        echo "✅ Realm 'demo' importado exitosamente"
    elif [ "$HTTP_CODE" == "409" ]; then
        echo "⚠️  El realm 'demo' ya existe. Si quieres actualizarlo, elimínalo primero desde la consola de administración."
    else
        echo "❌ Error al importar el realm. Código HTTP: $HTTP_CODE"
        echo "   Respuesta: $BODY"
        return 1
    fi
}

# Función principal
main() {
    case $1 in
        1)
            echo "🐘 Iniciando configuración estándar con PostgreSQL..."
            docker-compose up -d
            wait_for_keycloak
            echo ""
            echo "📋 Información de acceso:"
            echo "   - Keycloak Admin: http://localhost:8080"
            echo "   - Usuario: admin / Password: admin"
            echo "   - Demo App: http://localhost:3000"
            echo ""
            echo "💡 Tip: Puedes importar el realm 'demo' ejecutando: ./setup.sh 8"
            ;;
        2)
            echo "🔧 Iniciando configuración de desarrollo (H2 en memoria)..."
            docker-compose -f docker-compose.dev.yml up -d
            wait_for_keycloak
            echo ""
            echo "📋 Información de acceso:"
            echo "   - Keycloak Admin: http://localhost:8080"
            echo "   - Usuario: admin / Password: admin"
            echo "   - Demo App: http://localhost:3000"
            ;;
        3)
            echo "🏭 Iniciando configuración de producción..."
            if [ ! -f ".env" ]; then
                echo "⚠️  Advertencia: No se encontró el archivo .env"
                echo "   Creando uno básico desde .env.example..."
                if [ -f ".env.example" ]; then
                    cp .env.example .env
                    echo "   Por favor, edita .env con tus valores de producción"
                fi
            fi
            docker-compose -f docker-compose.prod.yml up -d
            wait_for_keycloak
            echo ""
            echo "📋 Servicios iniciados en modo producción"
            ;;
        4)
            echo "🛑 Deteniendo todos los servicios..."
            docker-compose down
            docker-compose -f docker-compose.dev.yml down 2>/dev/null || true
            docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
            echo "✅ Servicios detenidos"
            ;;
        5)
            echo "📜 Logs de Keycloak (Ctrl+C para salir)..."
            docker-compose logs -f keycloak 2>/dev/null || \
            docker-compose -f docker-compose.dev.yml logs -f keycloak 2>/dev/null || \
            docker-compose -f docker-compose.prod.yml logs -f keycloak
            ;;
        6)
            echo "📊 Estado de los servicios:"
            docker-compose ps 2>/dev/null || \
            docker-compose -f docker-compose.dev.yml ps 2>/dev/null || \
            docker-compose -f docker-compose.prod.yml ps 2>/dev/null || \
            echo "   No hay servicios corriendo"
            ;;
        7)
            echo "🧹 Limpiando todo (esto eliminará todos los datos)..."
            read -p "¿Estás seguro? (s/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                docker-compose down -v
                docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true
                docker-compose -f docker-compose.prod.yml down -v 2>/dev/null || true
                echo "✅ Limpieza completada"
            else
                echo "❌ Operación cancelada"
            fi
            ;;
        8)
            import_realm
            ;;
        9)
            echo "👋 ¡Hasta luego!"
            exit 0
            ;;
        *)
            if [ -z "$1" ]; then
                # Menú interactivo
                while true; do
                    show_menu
                    read -p "Opción: " choice
                    echo ""
                    main $choice
                    echo ""
                    read -p "Presiona Enter para continuar..."
                    echo ""
                done
            else
                echo "❌ Opción inválida: $1"
                echo "Usa './setup.sh' sin argumentos para ver el menú interactivo"
                exit 1
            fi
            ;;
    esac
}

# Ejecutar función principal
main "$@"



