#!/usr/bin/env bash

UTILS_DIR=${SCRIPT_DIR}/utils

COMPOSE_CMD=docker-compose
DOCKER_CMD=docker

ENVIRONMENT=${ENVIRONMENT:-dev}

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
