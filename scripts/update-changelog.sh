#!/bin/bash

docker run --rm -v $PWD:/opt/currents -e "GIT_CONFIG_PARAMETERS='safe.directory'='/opt/currents'" -w /opt/currents gembaadvantage/uplift changelog --no-stage 