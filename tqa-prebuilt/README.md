# Command Cluster 

docker-compose -f docker-compose-plf01.yml -f docker-compose-elasticsearch.yml -f docker-compose-ldap.yml -f docker-compose-mongo.yml -f docker-compose-mysql.yml  config > /tmp/docker-compose.yml && rsync -avP /tmp/docker-compose.yml qaf05:/srv/tmp