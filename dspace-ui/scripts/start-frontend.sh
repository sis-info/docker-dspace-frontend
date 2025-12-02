#!/bin/sh

# Script de inicio para DSpace Angular Frontend - Proyecto Independiente
# Ejecuta el build de producción y luego inicia el servidor
# Conecta a backend externo a través de host gateway
# Siguiendo documentación oficial de DSpace

echo "============================================"
echo "Iniciando DSpace Angular Frontend - Independiente..."
echo "Backend externo: ${DSPACE_REST_HOST:-dspace-backend.local}"
echo "HOST: ${DSPACE_UI_HOST:-0.0.0.0}"
echo "PORT: ${DSPACE_UI_PORT:-4000}"
echo "============================================"

# PASO 1: Generar dspace-ui.json desde template con variables de entorno
echo "Generando dspace-ui.json desde template con variables de entorno..."

# Ir al directorio de código fuente donde está el template
cd /dspace-angular

# Generar el archivo PM2 con las variables de entorno
echo "Variables de entorno para PM2:"
echo "  NODE_ENV: ${NODE_ENV:-production}"
echo "  DSPACE_REST_SSL: ${DSPACE_REST_SSL:-true}"
echo "  DSPACE_REST_HOST: ${DSPACE_REST_HOST:-localhost}"
echo "  DSPACE_REST_PORT: ${DSPACE_REST_PORT:-8080}"
echo "  DSPACE_REST_NAMESPACE: ${DSPACE_REST_NAMESPACE:-/server}"
echo "  DSPACE_UI_SSL: ${DSPACE_UI_SSL:-false}"
echo "  DSPACE_UI_HOST: ${DSPACE_UI_HOST:-0.0.0.0}"
echo "  DSPACE_UI_PORT: ${DSPACE_UI_PORT:-4000}"
echo "  DSPACE_UI_NAMESPACE: ${DSPACE_UI_NAMESPACE:-/}"

# Establecer valores por defecto para envsubst
export NODE_ENV=${NODE_ENV:-production}

# Usar configuración para frontend independiente conectando a backend externo
# Esto permite conexión a backend remoto a través del host gateway
export DSPACE_REST_SSL=${DSPACE_REST_SSL:-true}
export DSPACE_REST_HOST=${DSPACE_REST_HOST:-dspace-backend.local}
export DSPACE_REST_PORT=${DSPACE_REST_PORT:-443}
export DSPACE_REST_NAMESPACE=${DSPACE_REST_NAMESPACE:-/server}
export DSPACE_UI_SSL=${DSPACE_UI_SSL:-false}
export DSPACE_UI_HOST=${DSPACE_UI_HOST:-0.0.0.0}
export DSPACE_UI_PORT=${DSPACE_UI_PORT:-4000}
export DSPACE_UI_NAMESPACE=${DSPACE_UI_NAMESPACE:-/}

# Usar envsubst para reemplazar variables en el template
envsubst < dspace-ui.json > /dspace-ui-deploy/dspace-ui.json

echo "Archivo dspace-ui.json generado exitosamente:"
cat /dspace-ui-deploy/dspace-ui.json
echo "============================================"

# Verificar si ya existe el directorio dist
if [ ! -d "./dist" ]; then
    echo "Directorio dist no encontrado. Ejecutando build..."
else
    echo "Directorio dist encontrado. Verificando si necesita rebuild..."
    echo "Eliminando build anterior para fresh build..."
    rm -rf ./dist
fi

# Ejecutar build de producción con configuración de memoria aumentada
echo "Ejecutando yarn build:prod con memoria aumentada..."
export NODE_OPTIONS="--max-old-space-size=4096"
export NODE_ENV=production

# Ejecutar el build
echo "Build iniciado en directorio: $(pwd)"
yarn build:prod

if [ $? -ne 0 ]; then
    echo "Error: El build falló"
    exit 1
fi

echo "Build completado exitosamente"
echo "============================================"

# PASO CRÍTICO: Copiar dist a dspace-ui-deploy según documentación oficial
echo "Copiando /dist a [dspace-ui-deploy] según documentación oficial..."
cd /dspace-ui-deploy

# Remover dist anterior si existe
if [ -d "./dist" ]; then
    echo "Removiendo dist anterior en dspace-ui-deploy..."
    rm -rf ./dist
fi

# Copiar toda la carpeta dist (OBLIGATORIO según docs)
cp -r /dspace-angular/dist ./

if [ $? -ne 0 ]; then
    echo "Error: Falló la copia de dist a dspace-ui-deploy"
    exit 1
fi

echo "Copia completada. Estructura actual:"
ls -la /dspace-ui-deploy/
echo "Contenido de /dspace-ui-deploy/dist:"
ls -la /dspace-ui-deploy/dist/

echo "============================================"

# Configurar variables de entorno para Angular SSR
export HOST=${DSPACE_UI_HOST:-0.0.0.0}
export PORT=${DSPACE_UI_PORT:-4000}

# CRÍTICO: Deshabilitar verificación SSL para certificados autofirmados durante SSR
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Configuración SSL para SSR:"
echo "  NODE_TLS_REJECT_UNAUTHORIZED: $NODE_TLS_REJECT_UNAUTHORIZED"
echo "Iniciando servidor con PM2 desde [dspace-ui-deploy]..."
echo "Directorio actual: $(pwd)"
echo "HOST: $HOST"
echo "PORT: $PORT"
echo "============================================"

# Iniciar PM2 con la configuración desde dspace-ui-deploy
exec pm2-runtime start dspace-ui.json