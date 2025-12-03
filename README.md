# DSpace Frontend - Despliegue con Docker

Este proyecto contiene la configuración para desplegar únicamente el frontend de DSpace utilizando Docker, conectándose a un backend de DSpace externo.

## Prerrequisitos

### Sistema Operativo
- **Ubuntu 24.04 LTS** (recomendado)
- Distribuciones Linux compatibles con Docker

### Software Requerido
- **Docker Engine** versión 24.0 o superior
- **Docker Compose** versión 2.20 o superior

### Instalación de Docker en Ubuntu 24.04

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

# Agregar la clave GPG oficial de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Agregar el repositorio de Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Reiniciar para aplicar cambios de grupo
newgrp docker
```

## Estructura del Proyecto

```
docker-dspace-frontend/
├── docker-compose.yml          # Configuración principal de Docker Compose
├── .env.example               # Plantilla de variables de entorno
├── .env                       # Variables de entorno (no incluido en Git)
├── .gitignore                # Archivos ignorados por Git
├── README.md                 # Este archivo
│
├── dspace-ui/                # Aplicación Angular de DSpace
│   ├── Dockerfile            # Imagen del frontend
│   ├── dspace-ui.json        # Configuración de DSpace UI
│   ├── scripts/              # Scripts de inicio
│   └── src/                  # Código fuente Angular
│       ├── angular.json
│       ├── package.json
│       ├── config/           # Configuraciones de DSpace
│       └── ...
│
└── nginx/                    # Proxy reverso
    ├── conf.d/
    │   └── default.conf.template  # Configuración de Nginx
    └── ssl/                  # Certificados SSL (no incluidos)
        └── [certificados]
```

## Configuración del Despliegue

### 1. Clonar el Repositorio

```bash
git clone <url-del-repositorio>
cd docker-dspace-frontend
```

### 2. Configurar Variables de Entorno

```bash
# Copiar el archivo de ejemplo
cp .env.example .env

# Editar las variables según tu configuración
nano .env
```

#### Variables Importantes a Configurar:

```bash
# Nombre de tu institución
DSPACE_NAME="Mi Organización"

# URL del backend de DSpace (debe estar ejecutándose)
DSPACE_REST_HOST=dspace-backend.local
DSPACE_SERVER_URL=https://dspace-backend.local/server

# URL pública de tu frontend
DSPACE_UI_URL=https://mi-dspace.local
NGINX_HOST=mi-dspace.local

# Certificados SSL
NGINX_SSL=mi-dspace.local
CRT=mi-dspace.local.crt
KEY=mi-dspace.local.key
```

### 3. Configurar Certificados SSL

```bash
# Crear directorio para certificados
mkdir -p nginx/ssl/mi-dspace.local

# Copiar tus certificados SSL
cp mi-dspace.local.crt nginx/ssl/mi-dspace.local/
cp mi-dspace.local.key nginx/ssl/mi-dspace.local/
```

### 4. Configurar DNS/Hosts

Agregar entradas en `/etc/hosts` para resolución local:

```bash
# Agregar estas líneas a /etc/hosts
127.0.0.1    mi-dspace.local
<IP-BACKEND>  dspace-backend.local
```

## Pasos para el Despliegue

### 1. Construir las Imágenes

```bash
# Construir todas las imágenes
docker-compose build

# Ver las imágenes creadas
docker images
```

### 2. Iniciar los Servicios

```bash
# Iniciar en modo detached (background)
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f frontend-ui
docker-compose logs -f frontend-proxy
```

### 3. Verificar el Despliegue

```bash
# Verificar que los contenedores estén ejecutándose
docker-compose ps

# Verificar conectividad
curl -k https://mi-dspace.local
```

### 4. Acceder a la Aplicación

Abrir navegador y navegar a: `https://mi-dspace.local`

## Comandos Útiles

### Gestión de Contenedores

```bash
# Detener servicios
docker-compose down

# Reiniciar servicios
docker-compose restart

# Reconstruir y reiniciar
docker-compose up --build -d

# Ver uso de recursos
docker-compose top
```

### Logs y Depuración

```bash
# Logs de todos los servicios
docker-compose logs

# Logs con timestamp
docker-compose logs -t

# Seguir logs en tiempo real
docker-compose logs -f --tail=50

# Ejecutar shell en contenedor
docker-compose exec frontend-ui sh
docker-compose exec frontend-proxy sh
```

### Limpieza

```bash
# Detener y remover contenedores
docker-compose down

# Remover volúmenes
docker-compose down -v

# Limpiar imágenes no utilizadas
docker image prune -a

# Limpiar sistema completo
docker system prune -a
```

## Solución de Problemas

### Error: "host not found in upstream"
- Verificar que el servicio backend esté ejecutándose
- Comprobar la conectividad de red entre contenedores
- Revisar la configuración DNS

### Error: "SSL certificate not found"
- Verificar que los certificados estén en `nginx/ssl/`
- Comprobar los nombres de archivos en `.env`
- Verificar permisos de lectura

### Frontend no se conecta al backend
- Verificar variables `DSPACE_SERVER_URL` en `.env`
- Comprobar que el backend esté accesible desde el contenedor
- Revisar logs del frontend: `docker-compose logs frontend-ui`

## Características de Hardware

### Especificaciones para Producción Pequeña

Para una institución como el ICANH con 10-50 usuarios concurrentes:

```yaml
CPU: 4 cores / 4 vCPUs
RAM: 8 GB
Storage: 120 GB SSD
Network: 1 Gbps
Arquitectura: x86_64 (AMD64)
Sistema: Ubuntu 24.04 LTS
```

### Distribución del Almacenamiento

```bash
# Distribución recomendada del disco (120 GB total)
/                   - 20 GB   # Sistema base Ubuntu 24.04
/var/lib/docker     - 60 GB   # Imágenes y contenedores Docker
/var/log           - 15 GB   # Logs del sistema y aplicación
/opt/ssl           - 5 GB    # Certificados SSL
/opt/dspace-data   - 20 GB   # Datos de la aplicación y cache
```

### Consideraciones de Memoria

```javascript
// Distribución estimada de RAM (8 GB total)
const memoryAllocation = {
  nodeJs: '3 GB',      // Angular SSR + aplicación
  nginx: '512 MB',     // Proxy reverso
  docker: '1 GB',      // Docker daemon y overhead
  sistema: '3.5 GB'    // Ubuntu y procesos del sistema
};
```

### Optimizaciones del Sistema Ubuntu

```bash
# /etc/sysctl.conf - Configuraciones del kernel
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
vm.max_map_count = 262144
fs.file-max = 2097152

# /etc/security/limits.conf - Límites de sistema
* soft nofile 65535
* hard nofile 65535
* soft nproc 32768
* hard nproc 32768
```

### Puertos de Red Requeridos

```bash
22/tcp   # SSH para administración
80/tcp   # HTTP (redirección automática a HTTPS)
443/tcp  # HTTPS (acceso principal a la aplicación)
```

### Monitoreo de Recursos

```bash
# Comandos para verificar recursos del sistema
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
free -h && cat /proc/meminfo | grep Available
df -h && docker system df
```

**Alertas Recomendadas:**
- CPU > 80% por más de 5 minutos
- RAM > 85% utilizada
- Disco > 85% lleno
- Conexiones de red > 1000 activas

## Configuración de Producción

### Seguridad
- Usar certificados SSL válidos
- Configurar firewall adecuado
- Actualizar regularmente las imágenes base

### Rendimiento
- Configurar límites de memoria y CPU en docker-compose.yml
- Implementar monitoreo con herramientas como Prometheus
- Configurar backup de volúmenes si es necesario

### Mantenimiento
- Programar actualizaciones regulares
- Monitorear logs de aplicación
- Implementar rotación de logs

## Soporte

Para problemas específicos de DSpace, consultar:
- [Documentación oficial de DSpace](https://wiki.lyrasis.org/display/DSDOC7x)
- [Repositorio de DSpace Angular](https://github.com/DSpace/dspace-angular)

Para problemas de Docker:
- [Documentación de Docker](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)