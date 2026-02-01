#!/bin/bash

# Meta NPE Labs - One-Click Startup Script
# Run this to start the FRR networking lab

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================"
echo "Meta NPE Labs - Starting FRR Lab"
echo -e "======================================${NC}"
echo ""

# Check Docker is running
echo "Checking Docker..."
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker is not running!${NC}"
    echo "Starting Docker Desktop..."
    open -a Docker
    echo "Waiting 30 seconds for Docker to start..."
    sleep 30
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}Docker failed to start. Please start Docker Desktop manually and try again.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Pull containerlab image if not exists
echo "Checking containerlab Docker image..."
if ! docker images | grep -q "ghcr.io/srl-labs/clab"; then
    echo "Pulling containerlab image..."
    docker pull ghcr.io/srl-labs/clab
fi
echo -e "${GREEN}✓ Containerlab image ready${NC}"
echo ""

# Navigate to lab directory
LAB_DIR="/Users/landigf/Desktop/Code/LANdi-container/containerlab/lab-examples/frr01"
if [ ! -d "$LAB_DIR" ]; then
    echo -e "${RED}✗ Lab directory not found: $LAB_DIR${NC}"
    exit 1
fi

cd "$LAB_DIR"
echo -e "${GREEN}✓ In lab directory: $LAB_DIR${NC}"
echo ""

# Clean up any existing lab
echo "Cleaning up any existing lab..."
docker ps -a | grep clab-frr01 | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Deploy the lab using containerlab Docker image
echo -e "${YELLOW}Deploying FRR lab (this takes 30-60 seconds)...${NC}"
docker run --rm -it --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$(pwd)":/workspace \
    -w /workspace \
    --entrypoint /bin/sh \
    ghcr.io/srl-labs/clab -c "containerlab deploy -t frr01.clab.yml"

echo ""
echo -e "${GREEN}✓ Lab deployed successfully!${NC}"
echo ""

# Wait for containers to be ready
echo "Waiting for containers to be ready..."
sleep 10

# Show running containers
echo -e "${BLUE}Running containers:${NC}"
docker ps --filter "name=clab-frr01" --format "table {{.Names}}\t{{.Status}}"
echo ""

# Create connection instructions
echo -e "${BLUE}======================================"
echo "Lab is ready! Here's what to do:"
echo -e "======================================${NC}"
echo ""
echo -e "${YELLOW}1. Connect to PC1:${NC}"
echo "   docker exec -it clab-frr01-PC1 sh"
echo ""
echo -e "${YELLOW}2. Inside the container, run these commands:${NC}"
echo "   ip a"
echo "   ip r"
echo "   ping -c 2 10.0.0.1"
echo "   ip neigh"
echo "   traceroute 10.0.2.1"
echo ""
echo -e "${YELLOW}3. Connect to routers:${NC}"
echo "   docker exec -it clab-frr01-R1 vtysh"
echo "   docker exec -it clab-frr01-R2 vtysh"
echo "   docker exec -it clab-frr01-R3 vtysh"
echo ""
echo -e "${YELLOW}4. When done, stop the lab:${NC}"
echo "   bash ~/Desktop/Code/LANdi-container/Meta-prep/scripts/stop-lab.sh"
echo ""
echo -e "${GREEN}Ready to learn networking! 🚀${NC}"
