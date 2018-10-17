FROM nginx

ARG NGINX_SERVER_NAME
ARG NGINX_UPSTREAM_HOST
ARG NGINX_UPSTREAM_PORT
ARG WEB_ENDPOINT

COPY nginx.conf.template /etc/nginx/conf.d/nginx.conf.template
RUN envsubst '$NGINX_SERVER_NAME $NGINX_UPSTREAM_HOST $NGINX_UPSTREAM_PORT $WEB_ENDPOINT' < /etc/nginx/conf.d/nginx.conf.template > /etc/nginx/conf.d/default.conf

CMD nginx -g 'daemon off;'
