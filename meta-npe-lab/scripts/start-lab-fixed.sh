#!/bin/bash

# Fix Docker network conflicts and start lab

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================"
echo "Meta NPE Labs - Starting FRR Lab"
echo -e "======================================${NC}"
echo ""

# Check Docker
echo "Checking Docker..."
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker is not running!${NC}"
    open -a Docker
    sleep 30
fi
echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Clean up conflicting networks
echo "Cleaning up conflicting Docker networks..."
docker network ls | grep "exercise11_bigdata-network" | awk '{print $1}' | xargs docker network rm 2>/dev/null || true
docker network ls | grep "exercise10_default" | awk '{print $1}' | xargs docker network rm 2>/dev/null || true
docker network ls | grep "exam_docker_lab_default" | awk '{print $1}' | xargs docker network rm 2>/dev/null || true
docker network ls | grep "clab" | awk '{print $1}' | xargs docker network rm 2>/dev/null || true
echo -e "${GREEN}✓ Cleaned up networks${NC}"
echo ""

# Clean up any old lab containers
echo "Cleaning up old lab containers..."
docker ps -a | grep clab-frr01 | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Navigate to lab
LAB_DIR="/Users/landigf/Desktop/Code/LANdi-container/containerlab/lab-examples/frr01"
cd "$LAB_DIR"

# Deploy the lab
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

# Wait for containers
sleep 10

# Show containers
echo -e "${BLUE}Running containers:${NC}"
docker ps --filter "name=clab-frr01" --format "table {{.Names}}\t{{.Status}}"
echo ""

# Instructions
echo -e "${BLUE}======================================"
echo "Lab is ready! Here's what to do:"
echo -e "======================================${NC}"
echo ""
echo -e "${YELLOW}1. Connect to PC1:${NC}"
echo "   docker exec -it clab-frr01-PC1 sh"
echo ""
echo -e "${YELLOW}2. Inside the container, run:${NC}"
echo "   ip a"
echo "   ip r"
echo "   ping -c 2 10.0.0.1"
echo "   ip neigh"
echo "   exit"
echo ""
echo -e "${YELLOW}3. To stop the lab:${NC}"
echo "   bash ~/Desktop/Code/LANdi-container/Meta-prep/scripts/stop-lab.sh"
echo ""
echo -e "${GREEN}Ready! 🚀${NC}"
