#!/bin/bash -eu

set +u
if [ -z "${DS}" ]; then
  echo "DS environment variable must exist"
  exit 1
fi
set -u

if [ ! -d "${DS}" ]; then
  echo "DS value (${DS}) must be an existing directory"
  echo "example : "
  ls -ald /srv/DS/DB-INT2/*
  exit 1
fi

echo
echo "Stop docker ..."
docker-compose -f /srv/tmp/docker-compose.yml stop

echo
echo "Umount directory ..."
umount /srv/bench/mongo

echo
echo "Create filesystem ..."
mkfs.xfs -f /dev/vg-nvme/bench-mongo

echo
echo "Mount directory ..."
mount /dev/vg-nvme/bench-mongo /srv/bench/mongo
# No dumps

echo
echo "Done"