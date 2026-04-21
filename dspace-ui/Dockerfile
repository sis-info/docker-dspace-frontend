# Dockerfile para DSpace Angular Frontend
# Preparación de entorno - Build se ejecuta en runtime
# Basado en las instrucciones oficiales de DSpace 8.x

FROM node:18-alpine

# Instalar dependencias de compilación, PM2 y gettext (para envsubst)
RUN apk add --no-cache python3 make g++ tini gettext && \
    npm install -g pm2

# Crear directorio de código fuente (equivalente a [dspace-angular])
WORKDIR /dspace-angular

# Copiar el código fuente desde el directorio local (src/)
COPY src/ .

# Instalar dependencias (según documentación oficial)
RUN yarn install --frozen-lockfile --ignore-engines

# Crear directorio de deployment (según documentación oficial: [dspace-ui-deploy])
RUN mkdir -p /dspace-ui-deploy

# Crear directorios necesarios en dspace-ui-deploy
RUN mkdir -p /dspace-ui-deploy/config /dspace-ui-deploy/logs

# Cambiar al directorio de deployment para runtime
WORKDIR /dspace-ui-deploy

# Copiar configuración de PM2 template al directorio de código fuente (se procesará en runtime)
COPY dspace-ui.json /dspace-angular/dspace-ui.json

# Copiar script de inicio antes de cambiar de usuario
COPY scripts/start-frontend.sh /usr/local/bin/start-frontend.sh

# Convertir terminaciones de línea y dar permisos de ejecución al script
RUN tr -d '\r' < /usr/local/bin/start-frontend.sh > /tmp/start-frontend.sh && \
    mv /tmp/start-frontend.sh /usr/local/bin/start-frontend.sh && \
    chmod +x /usr/local/bin/start-frontend.sh

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S dspace && \
    adduser -S -D -H -u 1001 -h /dspace-ui-deploy -s /sbin/nologin -G dspace dspace && \
    chown -R dspace:dspace /dspace-ui-deploy && \
    chown -R dspace:dspace /dspace-angular && \
    chown dspace:dspace /usr/local/bin/start-frontend.sh

# Mantener root al inicio para poder corregir permisos de volúmenes montados;
# el script reduce privilegios a dspace antes de ejecutar build/servidor.
RUN apk add --no-cache su-exec

# Puerto de la aplicación (según config: port 4000)
EXPOSE 4000

# Variables de entorno de producción
ENV NODE_ENV=production

# Usar tini como init system para manejo correcto de señales
ENTRYPOINT ["/sbin/tini", "--"]

# Iniciar con el script desde el volumen montado
CMD ["/usr/local/bin/start-frontend.sh"]

