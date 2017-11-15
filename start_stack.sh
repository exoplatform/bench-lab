#!/usr/bin/env bash

[ "${DEBUG}" ] && set -x

# #############################################################################
# Initialize
# #############################################################################
SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load common functions
source ${SCRIPT_DIR}/_functions.sh


echo "*** Environment : ${ENVIRONMENT} ***"

init


#cp -v ${CONF_DIR}/docker-compose-${ENVIRONMENT}.env ${INSTANCE_DIR}/docker-compose.env
#ln -s -f ${INSTANCE_DIR}/docker-compose.env ${INSTANCE_DIR}/.env
cp -v ${CONF_DIR}/docker-compose-${ENVIRONMENT}.env ${ENV_FILE}

[ "${DEBUG}" ] && addEnvProperty DEBUG ${DEBUG}

pushd ${INSTANCE_DIR}

echo Build docker-compose configuration

#### Configuration ####
##### PLF #####
addOrReplaceEnvProperty EXO_NODE_COUNT 1
addOrReplaceEnvProperty EXO_DB_POOL_IDM_INIT_SIZE  1
addOrReplaceEnvProperty EXO_DB_POOL_IDM_MAX_SIZE  10
addOrReplaceEnvProperty EXO_DB_POOL_JCR_INIT_SIZE  2
addOrReplaceEnvProperty EXO_DB_POOL_JCR_MAX_SIZE  5
addOrReplaceEnvProperty EXO_DB_POOL_JPA_INIT_SIZE  3
addOrReplaceEnvProperty EXO_DB_POOL_JPA_MAX_SIZE  20

# Apache Workers
addOrReplaceEnvProperty APACHE_THREAD_PER_CHILD 20
addOrReplaceEnvProperty APACHE_SERVER_LIMIT     25
addOrReplaceEnvProperty APACHE_ASYNC_REQUEST_WORKER 2
addOrReplaceEnvProperty APACHE_MAX_REQUEST_WORKER 500


loadProperties

#### PLF composes ####
plfId=0
while [ ${plfId} -lt ${EXO_NODE_COUNT} ]; do
    plfId=$(( $plfId + 1 ))
    echo Build docker-compose for plf node ${plfId}
    plfTemplate $plfId
done

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