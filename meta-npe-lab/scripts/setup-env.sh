#!/bin/bash

# Meta NPE Labs - Environment Setup and Verification Script
# Checks prerequisites and sets up containerlab environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "Meta NPE Labs - Environment Check"
echo "======================================"
echo ""

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print info
print_info() {
    echo -e "${NC}ℹ${NC} $1"
}

# Check OS
echo "Checking operating system..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
    print_warning "Running on macOS - containerlab will use Linux VM"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
    print_status 0 "Running on Linux - optimal for containerlab"
else
    OS="Unknown"
    print_status 1 "Unknown OS - may have issues"
fi
echo ""

# Check Docker
echo "Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    print_status 0 "Docker installed: $DOCKER_VERSION"
    
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        print_status 0 "Docker daemon is running"
    else
        print_status 1 "Docker daemon is NOT running - please start Docker"
        exit 1
    fi
else
    print_status 1 "Docker is NOT installed"
    print_info "Install Docker Desktop: https://www.docker.com/products/docker-desktop"
    exit 1
fi
echo ""

# Check containerlab
echo "Checking containerlab installation..."
if [[ "$OS" == "macOS" ]]; then
    # On macOS, containerlab runs via Docker or needs special setup
    print_info "On macOS, containerlab runs inside Docker Desktop's Linux VM"
    print_info "You have two options:"
    echo ""
    echo "Option 1 (Recommended): Use containerlab via Docker"
    echo "  alias containerlab='docker run --rm -it --privileged \\"
    echo "    --network host \\"
    echo "    -v /var/run/docker.sock:/var/run/docker.sock \\"
    echo "    -v \$(pwd):/workspace \\"
    echo "    -w /workspace \\"
    echo "    ghcr.io/srl-labs/clab'"
    echo ""
    echo "Option 2: Install via Homebrew (if available)"
    echo "  brew install containerlab"
    echo ""
    
    # Check if they already have it via Docker
    if docker run --rm ghcr.io/srl-labs/clab version &> /dev/null; then
        CLAB_VERSION=$(docker run --rm ghcr.io/srl-labs/clab version | grep version | awk '{print $2}')
        print_status 0 "Containerlab Docker image available: $CLAB_VERSION"
    else
        print_warning "Containerlab Docker image not found"
        echo ""
        read -p "Would you like to pull the containerlab Docker image? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Pulling containerlab Docker image..."
            docker pull ghcr.io/srl-labs/clab
            print_status 0 "Containerlab Docker image pulled successfully"
            echo ""
            print_info "Add this alias to your ~/.zshrc for easy use:"
            echo "  alias clab='docker run --rm -it --privileged --network host -v /var/run/docker.sock:/var/run/docker.sock -v \$(pwd):/workspace -w /workspace ghcr.io/srl-labs/clab'"
        else
            print_warning "Skipping containerlab setup"
        fi
    fi
else
    # Linux - use standard installation
    if command -v containerlab &> /dev/null; then
        CLAB_VERSION=$(containerlab version | grep version | awk '{print $2}')
        print_status 0 "Containerlab installed: $CLAB_VERSION"
    else
        print_status 1 "Containerlab is NOT installed"
        print_info "Install with: bash <(curl -sL https://get.containerlab.dev)"
        echo ""
        read -p "Would you like to install containerlab now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Installing containerlab..."
            bash <(curl -sL https://get.containerlab.dev)
            print_status 0 "Containerlab installed successfully"
        else
            print_warning "Skipping containerlab installation"
            exit 1
        fi
    fi
fi
echo ""

# Check for containerlab repo
echo "Checking for containerlab examples repo..."
PARENT_DIR=$(dirname "$(pwd)")
CLAB_REPO_PATH="$PARENT_DIR/containerlab"

if [ -d "$CLAB_REPO_PATH" ]; then
    print_status 0 "Containerlab repo found at: $CLAB_REPO_PATH"
else
    print_warning "Containerlab repo not found"
    echo ""
    read -p "Would you like to clone the containerlab examples repo? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Cloning containerlab repo..."
        git clone https://github.com/srl-labs/containerlab.git "$CLAB_REPO_PATH"
        print_status 0 "Containerlab repo cloned to: $CLAB_REPO_PATH"
    else
        print_warning "Skipping containerlab repo clone"
    fi
fi
echo ""

# Check available disk space
echo "Checking disk space..."
if [[ "$OS" == "macOS" ]]; then
    AVAILABLE_GB=$(df -H . | awk 'NR==2 {print $4}' | sed 's/G//')
else
    AVAILABLE_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
fi

if [ "${AVAILABLE_GB%.*}" -gt 10 ]; then
    print_status 0 "Sufficient disk space: ${AVAILABLE_GB}GB available"
else
    print_warning "Low disk space: ${AVAILABLE_GB}GB available (recommend >10GB)"
fi
echo ""

# Check for required Docker images
echo "Checking for common lab Docker images..."
IMAGES=("frrouting/frr:latest" "networkop/frr:latest")
for IMAGE in "${IMAGES[@]}"; do
    if docker images | grep -q "$(echo $IMAGE | cut -d: -f1)"; then
        print_status 0 "$IMAGE found locally"
    else
        print_info "$IMAGE not found (will be pulled when lab starts)"
    fi
done
echo ""

# Check network tools
echo "Checking for network troubleshooting tools..."

if [[ "$OS" == "macOS" ]]; then
    # On macOS, only check for tools that work on the host
    TOOLS=("ping" "traceroute" "dig" "nc" "tcpdump")
    print_info "Note: 'ss' and 'ip' are Linux tools - you'll use them inside containers"
else
    # On Linux, check for all tools
    TOOLS=("ping" "traceroute" "dig" "nc" "tcpdump" "ss" "ip")
fi

MISSING_TOOLS=()

for TOOL in "${TOOLS[@]}"; do
    if command -v $TOOL &> /dev/null; then
        print_status 0 "$TOOL is installed"
    else
        print_status 1 "$TOOL is NOT installed"
        MISSING_TOOLS+=($TOOL)
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo ""
    print_warning "Missing tools: ${MISSING_TOOLS[*]}"
    if [[ "$OS" == "macOS" ]]; then
        print_info "Install with: brew install ${MISSING_TOOLS[*]}"
    else
        print_info "Install with: sudo apt install ${MISSING_TOOLS[*]} # Ubuntu/Debian"
        print_info "            or: sudo yum install ${MISSING_TOOLS[*]} # RHEL/CentOS"
    fi
fi
echo ""

# Summary
echo "======================================"
echo "Environment Check Summary"
echo "======================================"
if [ ${#MISSING_TOOLS[@]} -eq 0 ] && [ -d "$CLAB_REPO_PATH" ]; then
    print_status 0 "Environment is ready for labs!"
    echo ""
    echo "Next steps:"
    echo "1. cd $CLAB_REPO_PATH/lab-examples/frr01"
    echo "2. bash run.sh"
    echo "3. Follow instructions in README.md"
else
    print_warning "Environment needs some setup - see messages above"
fi
echo ""

# Optional: Test lab capability
echo "======================================"
read -p "Would you like to test with a minimal lab? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Creating minimal test lab..."
    
    # Create a simple 2-node lab
    cat > /tmp/test-lab.clab.yml <<EOF
name: test-lab

topology:
  nodes:
    node1:
      kind: linux
      image: alpine:latest
    node2:
      kind: linux
      image: alpine:latest
  links:
    - endpoints: ["node1:eth1", "node2:eth1"]
EOF
    
    echo "Deploying test lab..."
    
    if [[ "$OS" == "macOS" ]]; then
        # Use Docker-based containerlab on macOS
        # Note: macOS doesn't support --network host, but test will still work
        if docker run --rm --privileged \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v /tmp:/tmp \
            -w /tmp \
            ghcr.io/srl-labs/clab deploy -t test-lab.clab.yml; then
            print_status 0 "Test lab deployed successfully!"
            echo ""
            echo "Test connectivity:"
            echo "  docker exec -it clab-test-lab-node1 ping -c 2 node2"
            echo ""
            echo "View running containers:"
            echo "  docker ps | grep clab-test-lab"
            echo ""
            echo "Cleanup when done:"
            echo "  docker run --rm -it --privileged --network host -v /var/run/docker.sock:/var/run/docker.sock -v /tmp:/tmp -w /tmp ghcr.io/srl-labs/clab destroy -t test-lab.clab.yml"
        else
            print_status 1 "Test lab deployment failed"
        fi
    else
        # Use native containerlab on Linux
        if sudo containerlab deploy -t /tmp/test-lab.clab.yml; then
            print_status 0 "Test lab deployed successfully!"
            echo ""
            echo "Test connectivity:"
            echo "  docker exec -it clab-test-lab-node1 ping -c 2 node2"
            echo ""
            echo "Cleanup when done:"
            echo "  sudo containerlab destroy -t /tmp/test-lab.clab.yml"
        else
            print_status 1 "Test lab deployment failed"
        fi
    fi
else
    print_info "Skipping test lab"
fi
echo ""

echo "Setup script complete!"
