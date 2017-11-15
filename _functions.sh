#!/usr/bin/env bash

# #############################################################################
# Initialize
# #############################################################################
SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

INSTANCE_DIR=instance

TEMPLATE_DIR=${SCRIPT_DIR}/templates
INSTANCE_DIR=${SCRIPT_DIR}/instance
UTILS_DIR=${SCRIPT_DIR}/utils
CONF_DIR=${SCRIPT_DIR}/config
# Global environment file
ENV_FILE=${INSTANCE_DIR}/instance.env
# Specific environement file
SPEC_ENV_FILE=${INSTANCE_DIR}/spec.env

PLF_SERVER_COUNT=1

COMPOSE_CMD=docker-compose
DOCKER_CMD=docker

DOCKER_TEMPLATE_CMD="docker run --rm -v ${TEMPLATE_DIR}:/templates -v ${INSTANCE_DIR}:/target -v ${UTILS_DIR}:/go --env-file ${ENV_FILE} --env-file ${SPEC_ENV_FILE} golang:1.9.1 go run template.go"

ENVIRONMENT=${ENVIRONMENT:-dev}

function init() {
    mkdir -p "${INSTANCE_DIR}"
    mkdir -p "${INSTANCE_DIR}/logs"
    touch "${SPEC_ENV_FILE}"
}

#####
# Add $1=value in the $3 file (default:${ENV_FILE}
# where value=if $1 variable value if exists or $2
function addOrReplaceEnvProperty() {
  local key=$1
  local value=${!1:-$2}
  local file=${3:-$ENV_FILE}

  if [ $(grep -c "^${key}=" ${file}) -gt 0 ]; then
    [ ${DEBUG} ] && echo "Updating value of ${key} to ${value} in ${file}"
    ## workaround to be platform independent (Macos)
    ## Be careful for property values with |
    ${DOCKER_CMD} run --rm -v $(dirname ${file}):/env alpine sed -i'' "s|^${key}=.*|${key}=${value}|g" /env/$(basename ${file})
#    mv -f ${file}.tmp $file
  else
    [ ${DEBUG} ] && echo "Adding value of ${key} to ${value} in ${file}"
    # Ensure the content will be added on a new line
    tail -c1 ${file} | read -r _ || echo >> ${file}
    echo "${key}=${value}" >> ${file}
  fi
  export $key="${value}"
}

function forceEnvProperty() {
  local key=$1
  local value=${2}
  local file=${3:-$ENV_FILE}

  unset $1
  addOrReplaceEnvProperty ${key} "${value}" ${file}
}

function loadProperties() {
  local file=${1:-$ENV_FILE}
  source ${file}
}

function template() {
  local templateName=$1
  local target=${2:-$1}

  ${DOCKER_TEMPLATE_CMD} /templates/${templateName} /target/${target}
}

function plfTemplate() {
  local nodeId=$1
  local templateName=docker-compose-plf-node.yml
  local target=docker-compose-plf-node${nodeId}.yml

  forceEnvProperty NODE_ID ${nodeId} ${SPEC_ENV_FILE}

  ${DOCKER_TEMPLATE_CMD} /templates/compose/${templateName} /target/compose-fragment/${target}
}

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
