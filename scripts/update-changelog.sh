#!/bin/bash

VERSION=$(grep '^version:' charts/currents/Chart.yaml | awk '{print $2}')

docker run --rm -v "$PWD:/app" \
  -e "GIT_CONFIG_PARAMETERS='safe.directory'='/app'" \
  -w /app ghcr.io/orhun/git-cliff/git-cliff --tag "currents-${VERSION}" -u --prepend CHANGELOG.md
