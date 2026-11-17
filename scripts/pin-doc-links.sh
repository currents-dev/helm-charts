#!/bin/bash
# Points the docs' links to files in this repo at the chart's release tag
# instead of main, so the published docs show the values.yaml of the chart
# users install, not one with unreleased values. Run on a CI checkout before
# publishing docs/; it edits the files in place.
set -euo pipefail

VERSION=$(grep '^version:' charts/currents/Chart.yaml | awk '{print $2}')
TAG="currents-${VERSION}"

find docs -name '*.md' -print0 | xargs -0 sed -i -E \
  "s#(github\.com/currents-dev/helm-charts/(blob|tree))/main/#\1/${TAG}/#g"

echo "Pinned docs links to ${TAG}"
