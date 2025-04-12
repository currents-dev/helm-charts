#!/bin/bash

docker run --rm --volume "$(pwd):/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t docs/configuration.md.gotmpl -s file -o ../../docs/configuration.md