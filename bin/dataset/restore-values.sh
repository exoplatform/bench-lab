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
umount /srv/bench/data

echo
echo "Creating the filesystem ..."
mkfs.ext4 /dev/vg-nvme/bench-data

echo
echo "Mount directory ..."
mount /dev/vg-nvme/bench-data /srv/bench/data

echo
echo "Extract data ..."
time pv ${DS}/gatein-data/data.tar | tar -x -C /srv/bench
# Environ 7 mn

echo
echo "Changing permissions ..."
chown -R 999:999 /srv/bench/data/
