#!/bin/sh

# Script de inicio para DSpace Angular Frontend - ICANH
# Optimizado con Rebuild Inteligente y persistencia de compilación

# Si el contenedor inicia como root, ajustar permisos de volúmenes montados
# y relanzar como usuario no-root para mantener seguridad.
if [ "$(id -u)" = "0" ]; then
    echo "Ajustando permisos de runtime para /dspace-ui-deploy..."
    mkdir -p /dspace-ui-deploy/dist /dspace-ui-deploy/logs /dspace-ui-deploy/config
    chown -R dspace:dspace /dspace-ui-deploy /dspace-angular
    exec su-exec dspace /usr/local/bin/start-frontend.sh "$@"
fi

echo "============================================"
echo "Iniciando DSpace Angular Frontend - Independiente..."
echo "Backend externo: ${DSPACE_REST_HOST:-dspace-backend.local}"
echo "============================================"

# PASO 1: Generar dspace-ui.json desde template
echo "Generando dspace-ui.json desde template con variables de entorno..."

cd /dspace-angular

# Establecer valores por defecto y exportar para envsubst
export NODE_ENV=${NODE_ENV:-production}
export DSPACE_REST_SSL=${DSPACE_REST_SSL:-true}
export DSPACE_REST_HOST=${DSPACE_REST_HOST:-dspace-backend.local}
export DSPACE_REST_PORT=${DSPACE_REST_PORT:-443}
export DSPACE_REST_NAMESPACE=${DSPACE_REST_NAMESPACE:-/server}
export DSPACE_UI_SSL=${DSPACE_UI_SSL:-false}
export DSPACE_UI_HOST=${DSPACE_UI_HOST:-0.0.0.0}
export DSPACE_UI_PORT=${DSPACE_UI_PORT:-4000}
export DSPACE_UI_NAMESPACE=${DSPACE_UI_NAMESPACE:-/}

envsubst < dspace-ui.json > /dspace-ui-deploy/dspace-ui.json

echo "Archivo dspace-ui.json generado en /dspace-ui-deploy/"
echo "============================================"

# PASO 2: Lógica de Rebuild Inteligente
# Se compila SI: No existe la carpeta dist O si FORCE_REBUILD es true
if [ ! -d "./dist" ] || [ "$FORCE_REBUILD" = "true" ]; then
    echo "INICIANDO PROCESO DE COMPILACIÓN (BUILD)..."
    
    if [ "$FORCE_REBUILD" = "true" ]; then
        echo "Causa: FORCE_REBUILD detectado como true."
    else
        echo "Causa: Directorio ./dist no encontrado (Primera ejecución)."
    fi

    # Limpiar build anterior para asegurar integridad
    rm -rf ./dist
    rm -rf /dspace-ui-deploy/dist

    # Ejecutar build de producción con memoria aumentada (Vital para Proxmox)
    echo "Ejecutando yarn build:prod (Esto puede tardar varios minutos)..."
    export NODE_OPTIONS="--max-old-space-size=4096"
    
    yarn build:prod

    if [ $? -ne 0 ]; then
        echo "ERROR: El build de Angular falló. Revisa la RAM asignada a la VM."
        exit 1
    fi

    echo "Build completado exitosamente."
    
    # Copiar dist al directorio de despliegue según arquitectura DSpace
    echo "Sincronizando /dist con el directorio de despliegue..."
    cp -r /dspace-angular/dist /dspace-ui-deploy/
else
    echo "SALTANDO BUILD: Se detectó un build previo y FORCE_REBUILD=false."
    echo "El servidor iniciará inmediatamente."
fi

echo "============================================"

# PASO 3: Configuración de Runtime y SSR
cd /dspace-ui-deploy

export HOST=${DSPACE_UI_HOST:-0.0.0.0}
export PORT=${DSPACE_UI_PORT:-4000}

# CRÍTICO: Permitir certificados autofirmados del backend en el SSR
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Iniciando PM2 en modo Cluster..."
echo "Directorio: $(pwd) | Puerto: $PORT"
echo "============================================"

# Iniciar PM2 con el JSON generado
exec pm2-runtime start dspace-ui.json