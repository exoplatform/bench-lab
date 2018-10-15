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

docker-compose -f /srv/tmp/docker-compose.yml stop

umount /srv/bench/db

mkfs.ext4 /dev/vg-nvme/bench-db
mount /dev/vg-nvme/bench-db /srv/bench/db
mkdir /srv/bench/db/mysql

pv $DS/mysql-data/mysql-onedatabase.tar | tar x -C /srv/bench/db/
