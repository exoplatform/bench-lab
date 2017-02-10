#!/bin/bash -eu

function printUsage() {
  echo "$0 <ConfigMap name> <property file>"
}

if [ $# -ne 2 ]
then
  printUsage
  exit 1
fi

PARAMS=""

for line in $(cat $2)
do
  PARAMS="${PARAMS} --from-literal=${line}"
done

kubectl create configmap $1 ${PARAMS}

kubectl describe configmap $1
