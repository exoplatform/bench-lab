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


#### Apache configuration ####
# TODO Parameterization
# Workers
# Balancing between the number of nodes
mkdir -p ${INSTANCE_DIR}/config/apache
mkdir -p ${INSTANCE_DIR}/config/apache/include
cp -f ${CONF_DIR}/apache/httpd.conf ${INSTANCE_DIR}/config/apache
#cp -f ${CONF_DIR}/apache/include/proxy.conf ${INSTANCE_DIR}/config/apache/include
template config/apache/proxy.conf config/apache/include/proxy.conf

pushd ${INSTANCE_DIR}

echo Build docker-compose configuration

#### PLF configuration ####
addOrReplaceEnvProperty EXO_NODE_COUNT 1
addOrReplaceEnvProperty EXO_DB_POOL_IDM_INIT_SIZE  1
addOrReplaceEnvProperty EXO_DB_POOL_IDM_MAX_SIZE  10
addOrReplaceEnvProperty EXO_DB_POOL_JCR_INIT_SIZE  2
addOrReplaceEnvProperty EXO_DB_POOL_JCR_MAX_SIZE  5
addOrReplaceEnvProperty EXO_DB_POOL_JPA_INIT_SIZE  3
addOrReplaceEnvProperty EXO_DB_POOL_JPA_MAX_SIZE  20


loadProperties


#### Apache configuration ####
template compose/docker-compose-apache.yml compose-fragment/docker-compose-apache.yml

#### Patching templates ####
plfId=0
while [ ${plfId} -lt ${EXO_NODE_COUNT} ]; do
    plfId=$(( $plfId + 1 ))
    echo Build docker-compose for plf node ${plfId}
    plfTemplate $plfId
done

exit 0

# TODO Parameterization
# - database configuration
# - PLF propertiesÎ
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