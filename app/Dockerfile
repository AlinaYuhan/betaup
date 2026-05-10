FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html
RUN rm -f /usr/share/nginx/html/Dockerfile /usr/share/nginx/html/nginx.conf /usr/share/nginx/html/railway.json
CMD ["/bin/sh", "-c", "sed -i \"s/listen 80/listen ${PORT:-80}/g\" /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"]
