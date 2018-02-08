#!/usr/bin/env bash

[ "${DEBUG}" ] && set -x

# #############################################################################
# Initialize
# #############################################################################
SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load common functions
source ${SCRIPT_DIR}/_functions.sh

if [ -z "${JMETER_SCRIPT}" ]; then
  echo JMETER_SCRIPT environment variable is not defined
  exit 1
fi

JMETER_IMAGE=${JMETER_IMAGE:-exoplatform/jmeter}
JMETER_IMAGE_VERSION=${JMETER_IMAGE_VERSION:-latest}

JMETER_HEAP=${JMETER_HEAP:-512m}
JMETER_PERM_SIZE=${JMETER_PERM_SIZE:-128m}

JMETER_SCRIPT_DIR=${JMETER_SCRIPT_DIR:-$(pwd)}
JMETER_REPORT_DIR=${JMETER_REPORT_DIR:-$(pwd)}/results

## Dynamically building the test environment
PARAMETER_PREFIX="BENCHENV_"

# WARNING Not supporting spaces
PARAMETERS=$(env | grep ${PARAMETER_PREFIX})

PARAMETER_STRING=""
for i in ${PARAMETERS}
do
    PARAMETER_STRING="${PARAMETER_STRING} -J$(echo ${i} | cut -f2- -d"_")"
done

echo Creating report directory ${JMETER_REPORT_DIR}
mkdir -p -v ${JMETER_REPORT_DIR}

LOCAL_USER_ID=$(id -u)
echo "Using local UID : ${LOCAL_USER_ID}"

echo Running script with additional parameters : ${PARAMETER_STRING}

echo "Ensure the jmeter image is up to date"
${DOCKER_CMD} pull ${JMETER_IMAGE}:${JMETER_IMAGE_VERSION}

echo ###################################################################################################################
echo Beginning of the test : $(date)
echo ###################################################################################################################

DOCKER_ID=$(${DOCKER_CMD} run -d  \
  -v ${JMETER_SCRIPT_DIR}:/jmeter \
  -v ${JMETER_REPORT_DIR}:/output \
  -e HEAP="-Xms${JMETER_HEAP} -Xmx${JMETER_HEAP}" \
  -e LOCAL_USER_ID=${LOCAL_USER_ID} \
  ${JMETER_IMAGE}:${JMETER_IMAGE_VERSION} \
  -n \
  -t /jmeter/${JMETER_SCRIPT} \
  -j /output/jmeter.log \
  -l /output/benchmark.jtl \
  ${PARAMETER_STRING})
  # -o /output/results \

echo "Jmeter container id : ${DOCKER_ID}"

trap "docker kill ${DOCKER_ID}; docker rm -v ${DOCKER_ID}" EXIT

${DOCKER_CMD} logs -f ${DOCKER_ID}

${DOCKER_CMD} rm -v ${DOCKER_ID}

echo ###################################################################################################################
echo End of the test : $(date)
echo ###################################################################################################################

# Clean the trap on normal exit
trap - EXIT
