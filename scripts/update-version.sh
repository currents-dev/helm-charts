#!/bin/bash

# Check if yq is installed
if ! command -v yq &> /dev/null; then
  echo "Error: yq is not installed. Please install yq from https://github.com/mikefarah/yq/blob/master/README.md#install and try again."
  exit 1
fi

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --tag|-t) TAG="$2"; shift ;;
    --version|-v) VERSION="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

# Check if at least one of tag or version is provided
if [ -z "$TAG" ] && [ -z "$VERSION" ]; then
  echo "Error: You must provide at least one of --tag or --version."
  echo "Usage: $0 [--tag <tag>] [--version <version>]"
  exit 1
fi

# Update currents.imageTag in values.yaml if tag is provided
if [ -n "$TAG" ]; then
  yq -i ".currents.imageTag = \"$TAG\"" charts/currents/values.yaml
  yq -i ".appVersion = \"$TAG\"" charts/currents/Chart.yaml
  echo "Updated currents.imageTag and appVersion to $TAG"
fi

# Update version in Chart.yaml if version is provided
if [ -n "$VERSION" ]; then
  yq -i ".version = \"$VERSION\"" charts/currents/Chart.yaml
  echo "Updated version to $VERSION"
fi

# Call build-docs.sh script using a relative path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/build-docs.sh"