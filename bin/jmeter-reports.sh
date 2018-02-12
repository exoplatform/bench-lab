#!/usr/bin/env bash

[ "${DEBUG}" ] && set -x

generateReports() {
    echo ###################################################################################################################
    echo "Beginning of report generations : $(date)"
    echo ###################################################################################################################
    echo "$*"
    ${DOCKER_CMD} run --rm \
        -v ${JMETER_SCRIPT_DIR}:/jmeter \
        -v ${JMETER_REPORT_DIR}:/output \
        -w /usr/local/jmeter/ \
        -e HEAP="-Xms${JMETER_HEAP} -Xmx${JMETER_HEAP}" \
        -e JMETER_CMD="lib/ext/JMeterPluginsCMD.sh" \
        -e LOCAL_USER_ID=${LOCAL_USER_ID} \
        ${JMETER_IMAGE}:${JMETER_IMAGE_VERSION} \
        --input-jtl ${JTL_FILE} \
        $@
        # -o /output/results \
    echo ###################################################################################################################
    echo "End of report generation : $(date)"
    echo ###################################################################################################################
}

# #############################################################################
# Initialize
# #############################################################################
SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load common functions
source ${SCRIPT_DIR}/_functions.sh

JMETER_IMAGE=${JMETER_IMAGE:-exoplatform/jmeter}
JMETER_IMAGE_VERSION=${JMETER_IMAGE_VERSION:-latest}

JMETER_HEAP=${JMETER_HEAP:-512m}
JMETER_PERM_SIZE=${JMETER_PERM_SIZE:-128m}

JMETER_SCRIPT_DIR=${JMETER_SCRIPT_DIR:-$(pwd)}
JMETER_REPORT_DIR=${JMETER_REPORT_DIR:-$(pwd)}/results

JTL_FILE="/output/benchmark.jtl"

echo Checking report directory ${JMETER_REPORT_DIR}
if [ ! -d "${JMETER_REPORT_DIR}" ]; then
  echo "ERROR report dir ${JMETER_REPORT_DIR} does not exist"
  exit 1
fi

LOCAL_USER_ID=$(id -u)
echo "Using local UID : ${LOCAL_USER_ID}"

echo Generate bench statistics

# Temporary allow everybody to write on the report dir 
# to solve user mapping issue
chmod 777 ${JMETER_REPORT_DIR}
${DOCKER_CMD} run --rm \
-v ${SCRIPT_DIR}/../../tqa-scripts/JTLAnalyzer:/src \
-v ${JMETER_REPORT_DIR}:/output \
groovy:2.4.13-jdk8 groovy \
/src/src/PerfStats.groovy -f ${JTL_FILE} --step ${BENCHENV_expVUGUpStep}
# Restore permissions
chmod 770 ${JMETER_REPORT_DIR}

echo Generating CSV ...

COMMON_OPTIONS="--granulation 10000"
CSV_OPTIONS="${COMMON_OPTIONS}"

## CSV
### Agregated
generateReports --generate-csv /output/csv/benchmark-AggregateReport_Aggregated.csv \
                --plugin-type AggregateReport \
                ${CSV_OPTIONS} --aggregate-rows yes --relative-times no

generateReports --generate-csv /output/csv/benchmark-ResponseTimesOverTime_Aggregated.csv \
                --plugin-type ResponseTimesOverTime \
                ${CSV_OPTIONS} --aggregate-rows yes --relative-times no

generateReports --generate-csv /output/csv/benchmark-TransactionsPerSecond_Aggregated.csv \
                --plugin-type TransactionsPerSecond \
                ${CSV_OPTIONS} --aggregate-rows yes --relative-times no

generateReports --generate-csv /output/csv/benchmark-ResponseTimesVsThreads_Aggregated.csv \
                --plugin-type TimesVsThreads \
                ${CSV_OPTIONS} --aggregate-rows yes --relative-times no

generateReports --generate-csv /output/csv/benchmark-ThreadsStateOverTime_Aggregated.csv \
                --plugin-type ThreadsStateOverTime \
                ${CSV_OPTIONS} --aggregate-rows yes --relative-times no

### Non agregated
generateReports --generate-csv /output/csv/benchmark-ResponseTimesOverTime_Details.csv \
                --plugin-type ResponseTimesOverTime \
                ${CSV_OPTIONS} --aggregate-rows no --relative-times no

generateReports --generate-csv /output/csv/benchmark-ThroughputOverTime_Details.csv \
                --plugin-type ThroughputOverTime \
                ${CSV_OPTIONS} --aggregate-rows no --relative-times no

generateReports --generate-csv /output/csv/benchmark-TransactionsPerSecond_Details.csv \
                --plugin-type TransactionsPerSecond \
                ${CSV_OPTIONS} --aggregate-rows no --relative-times no

generateReports --generate-csv /output/csv/benchmark-ResponseTimesVsThreads_Details.csv \
                --plugin-type TimesVsThreads \
                ${CSV_OPTIONS} --aggregate-rows no

generateReports --generate-csv /output/csv/benchmark-ThroughputVsThreads_Details.csv \
                --plugin-type ThroughputVsThreads \
                ${CSV_OPTIONS} --aggregate-rows no


## PNG
echo Generating PNG
### Agregated
generateReports --generate-png /output/png/benchmark-ResponseTimesOverTime_Aggregated.png \
                --plugin-type ResponseTimesOverTime \
                ${CSV_OPTIONS} --aggregate-rows yes --relative-times no

generateReports --generate-png /output/png/benchmark-TransactionsPerSecond_Aggregated.png \
                --plugin-type TransactionsPerSecond \
                ${CSV_OPTIONS} --aggregate-rows yes --relative-times no

generateReports --generate-png /output/png/benchmark-ResponseTimesVsThreads_Aggregated.png \
                --plugin-type TimesVsThreads \
                ${CSV_OPTIONS} --aggregate-rows yes --relative-times no

generateReports --generate-png /output/png/benchmark-ThreadsStateOverTime_Aggregated.png \
                --plugin-type ThreadsStateOverTime \
                ${CSV_OPTIONS} --aggregate-rows yes --relative-times no

### Non agregated
generateReports --generate-png /output/png/benchmark-ResponseTimesOverTime_Details.png \
                --plugin-type ResponseTimesOverTime \
                ${CSV_OPTIONS} --aggregate-rows no --relative-times no

generateReports --generate-png /output/png/benchmark-ThroughputOverTime_Details.png \
                --plugin-type ThroughputOverTime \
                ${CSV_OPTIONS} --aggregate-rows no --relative-times no

generateReports --generate-png /output/png/benchmark-TransactionsPerSecond_Details.png \
                --plugin-type TransactionsPerSecond \
                ${CSV_OPTIONS} --aggregate-rows no --relative-times no

generateReports --generate-png /output/png/benchmark-ResponseTimesVsThreads_Details.png \
                --plugin-type TimesVsThreads \
                ${CSV_OPTIONS} --aggregate-rows no

generateReports --generate-png /output/png/benchmark-ThroughputVsThreads_Details.png \
                --plugin-type ThroughputVsThreads \
                ${CSV_OPTIONS} --aggregate-rows no

echo ###################################################################################################################
echo "End of the test : $(date)"
echo ###################################################################################################################

