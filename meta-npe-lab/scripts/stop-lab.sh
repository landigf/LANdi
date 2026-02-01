#!/bin/bash

# Meta NPE Labs - Stop Lab Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Stopping FRR lab...${NC}"

LAB_DIR="/Users/landigf/Desktop/Code/LANdi-container/containerlab/lab-examples/frr01"
cd "$LAB_DIR"

# Destroy the lab
docker run --rm -it --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$(pwd)":/workspace \
    -w /workspace \
    --entrypoint /bin/sh \
    ghcr.io/srl-labs/clab -c "containerlab destroy -t frr01.clab.yml" 2>/dev/null || true

# Clean up any remaining containers
docker ps -a | grep clab-frr01 | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true

echo -e "${GREEN}✓ Lab stopped and cleaned up${NC}"
