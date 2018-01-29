#!/usr/bin/env bash

PLF_SERVER_COUNT=1

function plf_init() {
    mkdir -p "${INSTANCE_DIR}"
    mkdir -p "${INSTANCE_DIR}/logs"
    touch "${SPEC_ENV_FILE}"
}

function plfTemplate() {
  local nodeId=$1
  local templateName=docker-compose-plf-node.yml
  local target=docker-compose-plf-node${nodeId}.yml

  echo Build docker-compose for plf node ${nodeId}

  forceEnvProperty NODE_ID ${nodeId} ${SPEC_ENV_FILE}
  forceEnvProperty NODE_IP "${EXO_CLUSTER_INSTANCE_IP_PREFIX}.$((${nodeId} + 10 ))" ${SPEC_ENV_FILE}

  ${DOCKER_TEMPLATE_CMD} /templates/compose/${templateName} /target/compose-fragment/${target}
}

function wait_plf_startup() {
  local compose=$1
  local instance=$2
  local plf_started=0
  echo Waiting for plf to start ...
  ${COMPOSE_CMD} -f ${compose} logs -f --no-color ${instance} | while read line
  do
    echo "$line"
    if [[ "$line" =~ "Server startup" ]]
    then
      echo "####### PLF Server ${instance} started successfully !"
      return 0
    fi

  done
}
