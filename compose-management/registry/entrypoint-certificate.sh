#!/bin/sh

echo $@

if [ ! -e "/certs/cert.key" ]; then
  echo No certificate detected, creating a new one
  echo '========================'
  openssl req -newkey rsa:4096 -nodes -sha256 -keyout /certs/registry.key -x509 -days 365 -out certs/registry.crt -subj '/'
fi

/entrypoint.orig.sh $@