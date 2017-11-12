#!/usr/bin/env bash

# #############################################################################
# Initialize
# #############################################################################
SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

INSTANCE_DIR=instance

TEMPLATE_DIR=${SCRIPT_DIR}/compose-templates
INSTANCE_DIR=${SCRIPT_DIR}/instance
CONF_DIR=${SCRIPT_DIR}/config

PLF_SERVER_COUNT=1

COMPOSE_CMD=docker-compose

ENVIRONMENT=${ENVIRONMENT:-dev}
