.PHONY: help up up-dev up-prod down logs status clean import-realm wait-keycloak

help: ## Mostrar esta ayuda
	@echo "Keycloak Demo - Comandos disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Iniciar configuración estándar (PostgreSQL)
	@echo "🚀 Iniciando configuración estándar..."
	docker-compose up -d
	@$(MAKE) wait-keycloak
	@echo ""
	@echo "✅ Servicios iniciados:"
	@echo "   - Keycloak: http://localhost:8080 (admin/admin)"
	@echo "   - Demo App: http://localhost:3000"

up-dev: ## Iniciar configuración de desarrollo (H2 en memoria)
	@echo "🔧 Iniciando configuración de desarrollo..."
	docker-compose -f docker-compose.dev.yml up -d
	@$(MAKE) wait-keycloak
	@echo ""
	@echo "✅ Servicios iniciados:"
	@echo "   - Keycloak: http://localhost:8080 (admin/admin)"
	@echo "   - Demo App: http://localhost:3000"

up-prod: ## Iniciar configuración de producción
	@echo "🏭 Iniciando configuración de producción..."
	@if [ ! -f .env ]; then \
		echo "⚠️  Creando .env desde .env.example..."; \
		cp .env.example .env 2>/dev/null || true; \
	fi
	docker-compose -f docker-compose.prod.yml up -d
	@$(MAKE) wait-keycloak
	@echo "✅ Servicios iniciados en modo producción"

down: ## Detener todos los servicios
	@echo "🛑 Deteniendo servicios..."
	docker-compose down
	docker-compose -f docker-compose.dev.yml down 2>/dev/null || true
	docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
	@echo "✅ Servicios detenidos"

logs: ## Ver logs de Keycloak
	docker-compose logs -f keycloak 2>/dev/null || \
	docker-compose -f docker-compose.dev.yml logs -f keycloak 2>/dev/null || \
	docker-compose -f docker-compose.prod.yml logs -f keycloak

status: ## Ver estado de los servicios
	@echo "📊 Estado de los servicios:"
	docker-compose ps 2>/dev/null || \
	docker-compose -f docker-compose.dev.yml ps 2>/dev/null || \
	docker-compose -f docker-compose.prod.yml ps 2>/dev/null || \
	echo "   No hay servicios corriendo"

clean: ## Limpiar todo (detener y eliminar volúmenes)
	@echo "🧹 Limpiando todo (esto eliminará todos los datos)..."
	@read -p "¿Estás seguro? (s/N): " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Ss]$$ ]]; then \
		docker-compose down -v; \
		docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true; \
		docker-compose -f docker-compose.prod.yml down -v 2>/dev/null || true; \
		echo "✅ Limpieza completada"; \
	else \
		echo "❌ Operación cancelada"; \
	fi

wait-keycloak: ## Esperar a que Keycloak esté listo
	@echo "⏳ Esperando a que Keycloak esté listo..."
	@for i in $$(seq 1 30); do \
		if curl -s -f http://localhost:8080/health/ready > /dev/null 2>&1; then \
			echo "✅ Keycloak está listo!"; \
			exit 0; \
		fi; \
		echo "   Intento $$i/30..."; \
		sleep 2; \
	done; \
	echo "❌ Keycloak no respondió después de 30 intentos"; \
	exit 1

import-realm: ## Importar el realm demo
	@echo "📥 Importando realm 'demo'..."
	@if [ ! -f "keycloak-config/realm-demo.json" ]; then \
		echo "❌ Error: No se encontró keycloak-config/realm-demo.json"; \
		exit 1; \
	fi
	@TOKEN=$$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
		-H "Content-Type: application/x-www-form-urlencoded" \
		-d "username=admin" \
		-d "password=admin" \
		-d "grant_type=password" \
		-d "client_id=admin-cli" | jq -r '.access_token'); \
	if [ "$$TOKEN" == "null" ] || [ -z "$$TOKEN" ]; then \
		echo "❌ Error: No se pudo obtener el token de acceso"; \
		exit 1; \
	fi; \
	RESPONSE=$$(curl -s -w "\n%{http_code}" -X POST http://localhost:8080/admin/realms \
		-H "Authorization: Bearer $$TOKEN" \
		-H "Content-Type: application/json" \
		-d @keycloak-config/realm-demo.json); \
	HTTP_CODE=$$(echo "$$RESPONSE" | tail -n1); \
	if [ "$$HTTP_CODE" == "201" ]; then \
		echo "✅ Realm 'demo' importado exitosamente"; \
	elif [ "$$HTTP_CODE" == "409" ]; then \
		echo "⚠️  El realm 'demo' ya existe"; \
	else \
		echo "❌ Error al importar el realm. Código HTTP: $$HTTP_CODE"; \
		exit 1; \
	fi

rebuild: ## Reconstruir la imagen de la aplicación demo
	@echo "🔨 Reconstruyendo imagen de la aplicación demo..."
	docker-compose build demo-app
	@echo "✅ Imagen reconstruida"



