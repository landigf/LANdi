#!/bin/bash

# Containerlab wrapper for macOS
# Usage: bash clab-macos.sh <containerlab-commands>
# Example: bash clab-macos.sh deploy -t mylab.yml

docker run --rm -it --privileged \
    --network host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$(pwd)":/workspace \
    -w /workspace \
    ghcr.io/srl-labs/clab "$@"
