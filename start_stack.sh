#!/usr/bin/env bash

# #############################################################################
# Initialize
# #############################################################################
SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load common functions
source ${SCRIPT_DIR}/_functions.sh

mkdir -p ${INSTANCE_DIR}

#### Apache configuration ####
# TODO Parameterization
# Workers
# Balancing between the number of nodes
mkdir -p ${INSTANCE_DIR}/config/apache
mkdir -p ${INSTANCE_DIR}/config/apache/include
cp -f ${CONF_DIR}/apache/httpd.conf ${INSTANCE_DIR}/config/apache
cp -f ${CONF_DIR}/apache/include/proxy.conf ${INSTANCE_DIR}/config/apache/include

pushd ${INSTANCE_DIR}

echo Build docker-compose configuration
docker-compose \
   -f ${TEMPLATE_DIR}/docker-compose-mysql.yml \
   -f ${TEMPLATE_DIR}/docker-compose-plf-node1.yml \
   -f ${TEMPLATE_DIR}/docker-compose-search.yml \
   -f ${TEMPLATE_DIR}/docker-compose-mongo.yml \
   -f ${TEMPLATE_DIR}/docker-compose-mail.yml \
   -f ${TEMPLATE_DIR}/docker-compose-apache.yml \
   config > ${INSTANCE_DIR}/docker-compose.yml

cat ${INSTANCE_DIR}/docker-compose.yml

echo Starting services
docker-compose up -d

docker-compose logs -f &
pid_log=$$


