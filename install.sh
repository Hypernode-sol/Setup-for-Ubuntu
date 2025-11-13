#!/bin/bash
set -e

# Hypernode Automated Setup Script
# Usage: ./install.sh --role [worker|validator|full] --gpu [nvidia|amd|none]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
ROLE=${ROLE:-worker}
GPU_TYPE=${GPU_TYPE:-nvidia}

while [[ $# -gt 0 ]]; do
    case $1 in
        --role)
            ROLE="$2"
            shift 2
            ;;
        --gpu)
            GPU_TYPE="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: ./install.sh --role [worker|validator|full] --gpu [nvidia|amd|none]"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🚀 Hypernode Setup${NC}"
echo -e "   Role: ${GREEN}$ROLE${NC}"
echo -e "   GPU: ${GREEN}$GPU_TYPE${NC}"
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
    echo -e "${BLUE}📋 Detected OS:${NC} $NAME $VERSION"
else
    echo -e "${RED}❌ Unsupported OS - cannot detect /etc/os-release${NC}"
    exit 1
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Do not run this script as root${NC}"
    echo "Run as normal user - script will use sudo when needed"
    exit 1
fi

# Check internet connection
if ! ping -c 1 google.com &> /dev/null; then
    echo -e "${RED}❌ No internet connection detected${NC}"
    exit 1
fi

# Update system
echo ""
echo -e "${BLUE}📦 Updating system packages...${NC}"
sudo apt update -qq || { echo -e "${RED}Failed to update package lists${NC}"; exit 1; }
sudo apt upgrade -y -qq || { echo -e "${YELLOW}Warning: Some packages failed to upgrade${NC}"; }

# Install essential packages
echo -e "${BLUE}📦 Installing essential packages...${NC}"
sudo apt install -y -qq curl wget git build-essential software-properties-common \
    || { echo -e "${RED}Failed to install essential packages${NC}"; exit 1; }

# Install Docker
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}🐳 Installing Docker...${NC}"
    curl -fsSL https://get.docker.com | sh || { echo -e "${RED}Failed to install Docker${NC}"; exit 1; }
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${BLUE}🐙 Installing Docker Compose...${NC}"
    sudo apt install -y docker-compose || { echo -e "${RED}Failed to install Docker Compose${NC}"; exit 1; }
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✓ Docker Compose already installed${NC}"
fi

# Install Node.js 20
if ! command -v node &> /dev/null || [ "$(node -v | cut -d'v' -f2 | cut -d'.' -f1)" -lt "20" ]; then
    echo -e "${BLUE}📗 Installing Node.js 20...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || { echo -e "${RED}Failed to add Node.js repository${NC}"; exit 1; }
    sudo apt install -y nodejs || { echo -e "${RED}Failed to install Node.js${NC}"; exit 1; }
    echo -e "${GREEN}✓ Node.js $(node -v) installed${NC}"
else
    echo -e "${GREEN}✓ Node.js $(node -v) already installed${NC}"
fi

# Install Python 3.11
if ! command -v python3.11 &> /dev/null; then
    echo -e "${BLUE}🐍 Installing Python 3.11...${NC}"
    sudo add-apt-repository ppa:deadsnakes/ppa -y || { echo -e "${RED}Failed to add Python PPA${NC}"; exit 1; }
    sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip || { echo -e "${RED}Failed to install Python 3.11${NC}"; exit 1; }
    echo -e "${GREEN}✓ Python $(python3.11 --version) installed${NC}"
else
    echo -e "${GREEN}✓ Python $(python3.11 --version) already installed${NC}"
fi

# Install PostgreSQL 15 (for validator/full nodes)
if [ "$ROLE" = "validator" ] || [ "$ROLE" = "full" ]; then
    if ! command -v psql &> /dev/null; then
        echo -e "${BLUE}🐘 Installing PostgreSQL 15...${NC}"
        sudo apt install -y postgresql-15 postgresql-contrib-15 || { echo -e "${RED}Failed to install PostgreSQL${NC}"; exit 1; }
        sudo systemctl enable postgresql
        sudo systemctl start postgresql
        echo -e "${GREEN}✓ PostgreSQL installed${NC}"
    else
        echo -e "${GREEN}✓ PostgreSQL already installed${NC}"
    fi
fi

# Install Redis (for validator/full nodes)
if [ "$ROLE" = "validator" ] || [ "$ROLE" = "full" ]; then
    if ! command -v redis-cli &> /dev/null; then
        echo -e "${BLUE}🔴 Installing Redis...${NC}"
        sudo apt install -y redis-server || { echo -e "${RED}Failed to install Redis${NC}"; exit 1; }
        sudo systemctl enable redis-server
        sudo systemctl start redis-server
        echo -e "${GREEN}✓ Redis installed${NC}"
    else
        echo -e "${GREEN}✓ Redis already installed${NC}"
    fi
fi

# GPU Setup
if [ "$GPU_TYPE" = "nvidia" ]; then
    echo ""
    echo -e "${BLUE}🎮 Installing NVIDIA drivers and CUDA...${NC}"

    # Check if NVIDIA GPU exists
    if ! lspci | grep -i nvidia &> /dev/null; then
        echo -e "${YELLOW}⚠️  No NVIDIA GPU detected - skipping NVIDIA setup${NC}"
    else
        # Install NVIDIA driver
        sudo apt install -y nvidia-driver-535 || { echo -e "${YELLOW}Warning: Failed to install NVIDIA driver${NC}"; }

        # NVIDIA Container Toolkit
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
            sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        sudo apt update
        sudo apt install -y nvidia-container-toolkit || { echo -e "${YELLOW}Warning: Failed to install NVIDIA Container Toolkit${NC}"; }
        sudo systemctl restart docker

        echo -e "${GREEN}✓ NVIDIA drivers and CUDA toolkit installed${NC}"
        echo -e "${YELLOW}⚠️  You may need to reboot for GPU drivers to take effect${NC}"
    fi
elif [ "$GPU_TYPE" = "amd" ]; then
    echo -e "${BLUE}🎮 Installing AMD ROCm...${NC}"
    echo -e "${YELLOW}⚠️  AMD ROCm installation is complex - manual setup recommended${NC}"
    echo "See: https://docs.amd.com/bundle/ROCm-Installation-Guide-v5.4.3/page/How_to_Install_ROCm.html"
fi

# Clone repositories
echo ""
echo -e "${BLUE}📂 Setting up Hypernode directory...${NC}"
mkdir -p ~/hypernode
cd ~/hypernode

echo -e "${BLUE}📥 Cloning Hypernode repositories...${NC}"

repos=(
    "hypernode-backend"
    "hypernode-node-client"
    "hypernode-sdk-python"
)

for repo in "${repos[@]}"; do
    if [ ! -d "$repo" ]; then
        echo -e "  Cloning $repo..."
        git clone "https://github.com/Hypernode-sol/$repo.git" 2>&1 | grep -v "Cloning into" || true
    else
        echo -e "${GREEN}  ✓ $repo already exists${NC}"
    fi
done

# Setup backend (for validator/full nodes)
if [ "$ROLE" = "validator" ] || [ "$ROLE" = "full" ]; then
    echo ""
    echo -e "${BLUE}⚙️  Setting up backend...${NC}"
    cd ~/hypernode/hypernode-backend

    echo "  Installing dependencies..."
    npm install --silent || { echo -e "${RED}Failed to install backend dependencies${NC}"; exit 1; }

    # Generate random password for database
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

    # Create .env if it doesn't exist
    if [ ! -f .env ]; then
        cat > .env <<EOF
# Environment
NODE_ENV=production

# Server
PORT=3000
HOST=0.0.0.0

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hypernode
DB_USER=hypernode_user
DB_PASSWORD=$DB_PASSWORD
DB_POOL_SIZE=10

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Solana
SOLANA_RPC_URL=https://devnet.helius-rpc.com/?api-key=ff977ada-bd04-4148-bd39-7887b3e34ce9
SOLANA_COMMITMENT=confirmed

# Logging
LOG_LEVEL=info
EOF
        echo -e "${GREEN}  ✓ .env created${NC}"
    else
        echo -e "${GREEN}  ✓ .env already exists${NC}"
    fi

    # Create PostgreSQL user and database
    echo "  Creating PostgreSQL database..."
    sudo -u postgres psql -c "CREATE USER hypernode_user WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
    sudo -u postgres psql -c "CREATE DATABASE hypernode OWNER hypernode_user;" 2>/dev/null || true
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE hypernode TO hypernode_user;" 2>/dev/null || true

    # Run migrations
    if [ -f "src/database/migrate.js" ]; then
        echo "  Running database migrations..."
        npm run db:migrate || { echo -e "${YELLOW}Warning: Database migration failed${NC}"; }
    fi

    echo -e "${GREEN}✓ Backend setup complete${NC}"
fi

# Setup worker node
if [ "$ROLE" = "worker" ] || [ "$ROLE" = "full" ]; then
    echo ""
    echo -e "${BLUE}👷 Setting up worker node...${NC}"
    cd ~/hypernode/hypernode-node-client

    # Create virtual environment
    if [ ! -d "venv" ]; then
        echo "  Creating Python virtual environment..."
        python3.11 -m venv venv || { echo -e "${RED}Failed to create virtual environment${NC}"; exit 1; }
    fi

    source venv/bin/activate

    echo "  Installing Python dependencies..."
    pip install --quiet --upgrade pip
    pip install --quiet -r requirements.txt || { echo -e "${RED}Failed to install worker dependencies${NC}"; exit 1; }

    # Create .env if it doesn't exist
    if [ ! -f .env ]; then
        cat > .env <<EOF
# Backend API
BACKEND_URL=https://api.hypernodesolana.org

# Wallet
WALLET_PUBKEY=YOUR_WALLET_ADDRESS_HERE
NODE_TOKEN=YOUR_NODE_TOKEN_HERE

# GPU Configuration
GPU_MODEL=auto-detect
GPU_MEMORY=auto-detect

# Region
REGION=auto-detect

# Logging
LOG_LEVEL=info
EOF
        echo -e "${GREEN}  ✓ .env created${NC}"
        echo -e "${YELLOW}  ⚠️  Please edit ~/hypernode/hypernode-node-client/.env with your wallet address${NC}"
    else
        echo -e "${GREEN}  ✓ .env already exists${NC}"
    fi

    echo -e "${GREEN}✓ Worker node setup complete${NC}"
fi

# Final summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Hypernode setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo ""

if [ "$ROLE" = "worker" ]; then
    echo -e "${YELLOW}1.${NC} Edit configuration:"
    echo "   nano ~/hypernode/hypernode-node-client/.env"
    echo ""
    echo -e "${YELLOW}2.${NC} Add your wallet address and node token"
    echo ""
    echo -e "${YELLOW}3.${NC} Start the worker node:"
    echo "   cd ~/hypernode/hypernode-node-client"
    echo "   source venv/bin/activate"
    echo "   python src/main.py"
fi

if [ "$ROLE" = "validator" ]; then
    echo -e "${YELLOW}1.${NC} Configure firewall (allow port 3000):"
    echo "   sudo ufw allow 3000/tcp"
    echo ""
    echo -e "${YELLOW}2.${NC} Start the backend:"
    echo "   cd ~/hypernode/hypernode-backend"
    echo "   npm start"
fi

if [ "$ROLE" = "full" ]; then
    echo -e "${YELLOW}1.${NC} Edit worker configuration:"
    echo "   nano ~/hypernode/hypernode-node-client/.env"
    echo ""
    echo -e "${YELLOW}2.${NC} Configure firewall:"
    echo "   sudo ufw allow 3000/tcp"
    echo ""
    echo -e "${YELLOW}3.${NC} Start backend (in one terminal):"
    echo "   cd ~/hypernode/hypernode-backend"
    echo "   npm start"
    echo ""
    echo -e "${YELLOW}4.${NC} Start worker (in another terminal):"
    echo "   cd ~/hypernode/hypernode-node-client"
    echo "   source venv/bin/activate"
    echo "   python src/main.py"
fi

if [ "$GPU_TYPE" = "nvidia" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  NVIDIA GPU Setup:${NC}"
    echo "   If GPU drivers were just installed, reboot your system:"
    echo "   sudo reboot"
fi

echo ""
echo -e "${BLUE}📖 Documentation:${NC} https://docs.hypernodesolana.org"
echo -e "${BLUE}💬 Support:${NC} https://discord.gg/hypernode"
echo ""
