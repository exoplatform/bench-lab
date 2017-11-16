#!/usr/bin/env bash

[ "${DEBUG}" ] && set -x

# #############################################################################
# Initialize
# #############################################################################
SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load common functions
source ${SCRIPT_DIR}/_functions.sh
source ${SCRIPT_DIR}/_plf_functions.sh

echo "*** Environment : ${ENVIRONMENT} ***"

plf_init


#cp -v ${CONF_DIR}/docker-compose-${ENVIRONMENT}.env ${INSTANCE_DIR}/docker-compose.env
#ln -s -f ${INSTANCE_DIR}/docker-compose.env ${INSTANCE_DIR}/.env
cp -v ${CONF_DIR}/docker-compose-${ENVIRONMENT}.env ${ENV_FILE}

[ "${DEBUG}" ] && addEnvProperty DEBUG ${DEBUG}

pushd ${INSTANCE_DIR}

echo Build docker-compose configuration

#### Configuration ####
SERVICES="front db mongo search mail plf1 jmxtrans1"
##### PLF #####
addOrReplaceEnvProperty EXO_NODE_COUNT 1
addOrReplaceEnvProperty EXO_REGISTRATION false
addOrReplaceEnvProperty EXO_DB_POOL_IDM_INIT_SIZE  1
addOrReplaceEnvProperty EXO_DB_POOL_IDM_MAX_SIZE  10
addOrReplaceEnvProperty EXO_DB_POOL_JCR_INIT_SIZE  2
addOrReplaceEnvProperty EXO_DB_POOL_JCR_MAX_SIZE  5
addOrReplaceEnvProperty EXO_DB_POOL_JPA_INIT_SIZE  3
addOrReplaceEnvProperty EXO_DB_POOL_JPA_MAX_SIZE  20

addOrReplaceEnvProperty EXO_CLUSTER_IP_RANGE "172.16.251.0/24"
addOrReplaceEnvProperty EXO_CLUSTER_INSTANCE_IP_PREFIX 172.16.251

forceEnvProperty NODES_NAMES "plf1"
forceEnvProperty NODES_IPS   "${EXO_CLUSTER_INSTANCE_IP_PREFIX}.11"

if [ ${EXO_NODE_COUNT} -gt 1 ]; then
    for i in $(seq 2 $EXO_NODE_COUNT); do
        forceEnvProperty NODES_NAMES "${NODES_NAMES},plf${i}"
        forceEnvProperty NODES_IPS   "${NODES_IPS},${EXO_CLUSTER_INSTANCE_IP_PREFIX}.$((${i} +10))"

        SLAVE_COMPOSE_FILES="${SLAVE_COMPOSE_FILES} -f ${INSTANCE_DIR}/compose-fragment/docker-compose-plf-node${i}.yml"
        SLAVE_SERVICES="${SLAVE_SERVICES} plf${i} jmxtrans${i}"
    done
fi

plfTemplate 1
if [ ${EXO_NODE_COUNT} -gt 1 ]; then
    for i in $(seq 2 $EXO_NODE_COUNT); do
        plfTemplate $i
    done
fi

# Apache Workers
addOrReplaceEnvProperty APACHE_THREAD_PER_CHILD 20
addOrReplaceEnvProperty APACHE_SERVER_LIMIT     25
addOrReplaceEnvProperty APACHE_ASYNC_REQUEST_WORKER 2
addOrReplaceEnvProperty APACHE_MAX_REQUEST_WORKER 500

#### Apache compose ####
template compose/docker-compose-apache.yml compose-fragment/docker-compose-apache.yml

#### Apache configuration ####
# Balancing between the number of nodes
mkdir -p ${INSTANCE_DIR}/config/apache
mkdir -p ${INSTANCE_DIR}/config/apache/include
cp -rfv ${CONF_DIR}/apache ${INSTANCE_DIR}/config
#cp -f ${CONF_DIR}/apache/include/proxy.conf ${INSTANCE_DIR}/config/apache/include
template config/apache/httpd.conf
template config/apache/include/proxy.conf config/apache/include/proxy.conf

# TODO Parameterization
# - database configuration
# - PLF propertiesÎ
# - optional config file
# - patch
# - PLF version
${COMPOSE_CMD} \
   -f ${TEMPLATE_DIR}/compose/docker-compose-mysql.yml \
   -f ${INSTANCE_DIR}/compose-fragment/docker-compose-plf-node1.yml \
   -f ${TEMPLATE_DIR}/compose/docker-compose-search.yml \
   -f ${TEMPLATE_DIR}/compose/docker-compose-mongo.yml \
   -f ${TEMPLATE_DIR}/compose/docker-compose-mail.yml \
   -f ${INSTANCE_DIR}/compose-fragment/docker-compose-apache.yml \
   ${SLAVE_COMPOSE_FILES} \
   config > ${INSTANCE_DIR}/docker-compose.yml

echo Starting services and the first PLF Node
${COMPOSE_CMD} -f ${INSTANCE_DIR}/docker-compose.yml up -d --force-recreate ${SERVICES}

wait_plf_startup ${INSTANCE_DIR}/docker-compose.yml plf1
if [ $? -ne 0 ]; then
  echo Error detected during stack startup. Stopping...
  ${SCRIPT_DIR}/stop_stack.sh
  exit 1
fi

if [ ${EXO_NODE_COUNT} -gt 1 ]; then
  echo "Starting the other plf nodes..."
  ${COMPOSE_CMD} -f ${INSTANCE_DIR}/docker-compose.yml up -d --force-recreate ${SLAVE_SERVICES}

  for i in $(seq 2 $EXO_NODE_COUNT); do
      wait_plf_startup ${INSTANCE_DIR}/docker-compose-slaves.yml plf${i} &
  done
  wait
fi

echo "Stack started successfully"