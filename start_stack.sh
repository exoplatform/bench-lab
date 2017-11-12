#!/usr/bin/env bash

# #############################################################################
# Initialize
# #############################################################################
SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load common functions
source ${SCRIPT_DIR}/_functions.sh

echo "*** Environment : ${ENVIRONMENT} ***"

function wait_plf_startup() {
  local plf_started=0
  echo Waiting for plf to start ...
  ${COMPOSE_CMD} logs -f | while read line
  do
    echo "$line"
    if [[ "$line" =~ "Server startup" ]]
    then
      echo "####### PLF Server started successfully !"
      plf_started=$(( $plf_started + 1 ))
    fi

    if [[ "$line" == *"ERROR"* ]]
    then
      echo "Error detected on the logs..."
      return 1
    fi

    if [ ${plf_started} == ${PLF_SERVER_COUNT} ]; then
      echo All plf servers started
      return 0
    fi
  done
}

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

cp -v ${CONF_DIR}/docker-compose-${ENVIRONMENT}.env ${INSTANCE_DIR}/docker-compose.env
ln -s -f ${INSTANCE_DIR}/docker-compose.env ${INSTANCE_DIR}/.env

# TODO Parameterization
# - database configuration
# - PLF properties
# - optional config file
# - patch
# - PLF version
${COMPOSE_CMD} \
   -f ${TEMPLATE_DIR}/docker-compose-mysql.yml \
   -f ${TEMPLATE_DIR}/docker-compose-plf-node1.yml \
   -f ${TEMPLATE_DIR}/docker-compose-search.yml \
   -f ${TEMPLATE_DIR}/docker-compose-mongo.yml \
   -f ${TEMPLATE_DIR}/docker-compose-mail.yml \
   -f ${TEMPLATE_DIR}/docker-compose-apache.yml \
   config > ${INSTANCE_DIR}/docker-compose.yml

cat ${INSTANCE_DIR}/docker-compose.yml

echo Starting services
${COMPOSE_CMD} up -d

wait_plf_startup startup
if [ $? -ne 0 ]; then
  echo Error detected during stack startup. Stopping...
  ${SCRIPT_DIR}/stop_stack.sh
  exit 1
fi

echo "Stack started successfully"