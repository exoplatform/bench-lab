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
umount /srv/bench/elasticsearch

echo
echo "Create filesystem ..."
mkfs.ext4 /dev/vg-nvme/bench-es
chown 1000:1000 /srv/bench/elasticsearch

echo
echo "Mount directory ..."
mount /dev/vg-nvme/bench-es /srv/bench/elasticsearch

echo
echo "Preparing restore directory ..."
rm -rf /srv/bench/backup/elasticsearch/*
pv ${DS}/elasticsearch/snapshot.tar | tar -x -C /srv/bench/backup/elasticsearch
chown 1000:1000 /srv/bench/elasticsearch /srv/bench/backup/elasticsearch

echo
echo "Start elasticsearch for restorration ..."
# TODO Should start the container based on the docker file to always match the righ version
CONTAINER_ID=$(docker run -d --name elastic -e ES_JAVA_OPTS="-Xms8g -Xmx8g" -e path.repo="/backup" -e cluster.name=qaf05 -e http.max_content_length=400m -v /srv/bench/elasticsearch:/usr/share/elasticsearch/data -e xpack.monitoring.enabled=false -v /srv/bench/backup/elasticsearch:/backup -p 127.0.0.1:9200:9200 --net plf exoplatform/elasticsearch:1.2.0)
echo "Container ID : ${CONTAINER_ID}"

echo "Waiting for es availability..."
while ! curl -f -q http://localhost:9200
do
  echo -n .
  sleep 1
done

echo
echo "Configure snapshot directory ..."
curl -XPUT http://localhost:9200/_snapshot/backup -d '{"type":"fs", "settings": {"compress":true, "location":"/backup"}}'

echo
echo "Restore snapshot ..."
time curl -XPOST "http://localhost:9200/_snapshot/backup/plf/_restore?wait_for_completion=true"

echo
echo "Remove not necessary indices ..."
curl http://localhost:9200/_cat/indices?h=index | grep -e watcher -e monitoring | xargs -n1 -t -i{} curl -XDELETE http://localhost:9200/{}
curl -XPUT "http://localhost:9200/file/_settings" -d '{"index":{"number_of_replicas":0}}'
curl -XPUT "http://localhost:9200/wiki_v2/_settings" -d '{"index":{"number_of_replicas":0}}'
curl -XPUT "http://localhost:9200/space_v2/_settings" -d '{"index":{"number_of_replicas":0}}'
curl -XPUT "http://localhost:9200/profile_v2/_settings" -d '{"index":{"number_of_replicas":0}}'

echo
echo "Stopping container ..."
docker stop ${CONTAINER_ID}
docker rm -v ${CONTAINER_ID}

echo
echo "Done"