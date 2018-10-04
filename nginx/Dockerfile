FROM nginx
COPY nginx.conf.template /etc/nginx/conf.d/nginx.conf.template
CMD envsubst '$NGINX_SERVER_NAME $NGINX_UPSTREAM_HOST $NGINX_UPSTREAM_PORT $WEB_ENDPOINT' < /etc/nginx/conf.d/nginx.conf.template > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'
