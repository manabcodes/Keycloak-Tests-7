FROM nginx:alpine

# Crear directorios necesarios
RUN mkdir -p /usr/share/nginx/html/portal \
    && mkdir -p /usr/share/nginx/html/proyectos \
    && mkdir -p /usr/share/nginx/html/admin \
    && mkdir -p /usr/share/nginx/html/cliente

# Copiar todas las aplicaciones
COPY apps/portal-empleados.html /usr/share/nginx/html/portal/index.html
COPY apps/proyectos-app.html /usr/share/nginx/html/proyectos/index.html
COPY apps/panel-admin.html /usr/share/nginx/html/admin/index.html
COPY apps/cliente-app.html /usr/share/nginx/html/cliente/index.html
COPY index.html /usr/share/nginx/html/index.html

# Copiar configuración de nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
