ARG DOMAIN_NAME

FROM debian:13.6

ARG DOMAIN_NAME

RUN apt-get update -y && apt-get install -y \
    nginx \
    openssl

# Génère un certificat auto-signé pour TLS
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=${DOMAIN_NAME}"

COPY conf/nginx.conf /etc/nginx/sites-available/default

#RUN nginx -t

EXPOSE 443

ENTRYPOINT ["nginx", "-g", "daemon off;"]
