#!/bin/bash -eu

INSTANCE_DIR=instance

pushd ${INSTANCE_DIR}

docker-compose down -v