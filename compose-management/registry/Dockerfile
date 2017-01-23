FROM registry:2

RUN apk update && apk add openssl

RUN cp /entrypoint.sh /entrypoint.orig.sh && mkdir /certs

ENV REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt
ENV REGISTRY_HTTP_TLS_KEY=/certs/registry.key

COPY entrypoint-certificate.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh

#ENTRYPOINT /entrypoint-certificate.sh

