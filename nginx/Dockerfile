FROM nginx:alpine

# Copiar la configuración personalizada
COPY conf.d/ /etc/nginx/templates/

# Crear páginas de error personalizadas para evitar mostrar información del servidor
RUN mkdir -p /usr/share/nginx/html/error && \
    echo '<html><head><title>Error</title></head><body><h1>Error</h1><p>An error occurred.</p></body></html>' > /usr/share/nginx/html/error/40x.html && \
    echo '<html><head><title>Error</title></head><body><h1>Error</h1><p>An error occurred.</p></body></html>' > /usr/share/nginx/html/error/50x.html

# Exponer puertos
EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]