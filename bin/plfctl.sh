#!/bin/bash -eu

HOME_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

function printUsage() {
  echo "$0 [-d <database template>] -c <chat database template> <action>"
  echo "  -d <database template> : (optional) Plateform database template to use, default: mysql"
  echo "  -c <chat database template> : (optional) Database template to use for chat, default: mongo"
  echo "  -e <elasticsearch template> : (optional) Elasticsearch template to use : default : es"
  echo "  <action> : action to perform. Supported actions :"
  echo "      start :"
  echo "      stop  :"
  echo "      ps    :"
  echo "      logs  :"
}

function addPLF_DATABASE_TEMPLATE() {
  COMPOSE_OPTIONS="${COMPOSE_OPTIONS} "
}

# PLF_DATABASE_TEMPLATE=
# CHAT_DATABASE_TEMPLATE=
COMPOSE_OPTIONS=""

PLF_DATABASE_TEMPLATE=mysql
CHAT_DATABASE_TEMPLATE=mongo
ELASTICSEARCH_DATABASE_TEMPLATE=es

ACTION=DEFAULT_ACTION
while getopts "d:c:e:p:h" opt; do
  case $opt in
    h)
      printUsage
      exit 0;
      ;;
    d)
      PLF_DATABASE_TEMPLATE=$OPTARG
      ;;
    c)
      CHAT_DATABASE_TEMPLATE=$OPTARG
      ;;
    e)
      ELASTICSEARCH_DATABASE_TEMPLATE=$OPTARG
      ;;
  esac;
done

shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
  printUsage
  exit 1
fi

ACTION=$1
shift
ACTION_PARAMS=$*

case "${ACTION}" in
  start)
    COMPOSE_ACTION="up --force-recreate --no-deps -d"
    COMPOSE_ACTION_PARAM=""
    ;;
  stop)
    COMPOSE_ACTION="stop"
    COMPOSE_ACTION_PARAM=""
    ;;
  ps)
    COMPOSE_ACTION="ps"
    COMPOSE_ACTION_PARAM=""
    ;;
  logs)
    COMPOSE_ACTION="logs"
    COMPOSE_ACTION_PARAM="${ACTION_PARAMS}"
    ;;
  *)
    echo "Unknown action $ACTION"
    exit 1
    ;;
esac

PLF_DATABASE_COMPOSE="${HOME_DIR}/compose-plf/database/docker-compose-$PLF_DATABASE_TEMPLATE.yml"
if [ ! -e "${PLF_DATABASE_COMPOSE}" ]; then
  echo "PLF database compose is not found : ${PLF_DATABASE_COMPOSE}"
  exit 1
fi
PLF_DATABASE_ENV="${HOME_DIR}/compose-plf/database/docker-compose-$PLF_DATABASE_TEMPLATE.env"

if [ ! -e "${PLF_DATABASE_ENV}" ]; then
  echo "WARNING: PLF database env file not found : ${PLF_DATABASE_ENV}"
fi

if [ -n "${PLF_DATABASE_TEMPLATE}" ]; then
  COMPOSE_OPTIONS="${COMPOSE_OPTIONS} -f ${HOME_DIR}/compose-plf/database/docker-compose-$PLF_DATABASE_TEMPLATE.yml"
fi

if [ -n "${CHAT_DATABASE_TEMPLATE}" ]; then
  COMPOSE_OPTIONS="${COMPOSE_OPTIONS} -f ${HOME_DIR}/compose-plf/chat/docker-compose-$CHAT_DATABASE_TEMPLATE.yml"
fi

if [ -n "${ELASTICSEARCH_DATABASE_TEMPLATE}" ]; then
  COMPOSE_OPTIONS="${COMPOSE_OPTIONS} -f ${HOME_DIR}/compose-plf/elasticsearch/docker-compose-${ELASTICSEARCH_DATABASE_TEMPLATE}.yml"
fi

export PLF_DATABASE_TEMPLATE

docker-compose -f ${HOME_DIR}/compose-plf/plf/docker-compose-plf.yml $COMPOSE_OPTIONS $COMPOSE_ACTION $COMPOSE_ACTION_PARAM
