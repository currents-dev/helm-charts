#!/bin/bash

docker run --rm -v $PWD:/tmp -w /tmp gembaadvantage/uplift changelog --no-stage 