# Automated Install Script Documentation

Complete documentation for the `install.sh` automated setup script.

## Overview

The `install.sh` script provides one-command installation of Hypernode infrastructure on Ubuntu 20.04+ systems.

**Features**:
- Detects system configuration automatically
- Installs all required dependencies
- Configures databases and services
- Sets up GPU drivers (NVIDIA/AMD)
- Creates secure default configurations
- Validates installation at each step

## Quick Start

```bash
# Download script
wget https://raw.githubusercontent.com/Hypernode-sol/Setup-for-Ubuntu/main/install.sh

# Make executable
chmod +x install.sh

# Run (worker node with NVIDIA GPU)
./install.sh --role worker --gpu nvidia
```

## Usage

```bash
./install.sh --role [ROLE] --gpu [GPU_TYPE]
```

### Parameters

#### `--role` (required)
Determines which Hypernode components to install.

- **`worker`**: GPU compute node (executes jobs)
- **`validator`**: Backend API server (job queue, node registry)
- **`full`**: Both worker and validator

#### `--gpu` (optional, default: `nvidia`)
Configures GPU driver installation.

- **`nvidia`**: Install NVIDIA drivers + CUDA + container toolkit
- **`amd`**: Shows AMD ROCm installation instructions
- **`none`**: Skip GPU setup (CPU-only)

### Examples

```bash
# Worker node with NVIDIA GPU (most common)
./install.sh --role worker --gpu nvidia

# Validator node (no GPU needed)
./install.sh --role validator

# Full node with NVIDIA GPU
./install.sh --role full --gpu nvidia

# Worker with AMD GPU (manual ROCm setup required)
./install.sh --role worker --gpu amd

# CPU-only worker (testing/development)
./install.sh --role worker --gpu none
```

## Installation Process

### 1. System Validation

The script checks:
- ✅ Ubuntu OS detected (via `/etc/os-release`)
- ✅ Not running as root user
- ✅ Internet connection available
- ✅ System architecture compatible

**Failures**:
- ❌ Non-Ubuntu OS → Exits with error
- ❌ Running as root → Exits with security warning
- ❌ No internet → Cannot download packages

### 2. Package Updates

```bash
sudo apt update -qq
sudo apt upgrade -y -qq
```

Updates system package lists and upgrades installed packages.

**Duration**: 2-5 minutes

### 3. Essential Tools

Installs:
- `curl`, `wget` - Download tools
- `git` - Version control
- `build-essential` - Compilation tools
- `software-properties-common` - PPA management

**Duration**: 1-2 minutes

### 4. Docker Installation

If Docker not installed:
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Installs Docker CE and Docker Compose.

**Duration**: 3-5 minutes

**Note**: Requires logout/login for `docker` group membership to take effect.

### 5. Node.js 20

If Node.js < v20:
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

Installs Node.js 20.x (LTS) from official NodeSource repository.

**Duration**: 2-3 minutes

### 6. Python 3.11

If Python 3.11 not installed:
```bash
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip
```

Installs Python 3.11 from Deadsnakes PPA.

**Duration**: 2-3 minutes

### 7. PostgreSQL 15 (Validator/Full only)

If role is `validator` or `full`:
```bash
sudo apt install -y postgresql-15 postgresql-contrib-15
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

Installs and starts PostgreSQL 15.

**Duration**: 3-5 minutes

### 8. Redis (Validator/Full only)

If role is `validator` or `full`:
```bash
sudo apt install -y redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

Installs and starts Redis server.

**Duration**: 1-2 minutes

### 9. GPU Drivers

#### NVIDIA (`--gpu nvidia`)

```bash
# Check GPU exists
lspci | grep -i nvidia

# Install driver
sudo apt install -y nvidia-driver-535

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker
```

**Duration**: 5-10 minutes

**Note**: System reboot required after driver installation.

#### AMD (`--gpu amd`)

Shows manual installation instructions. AMD ROCm setup is complex and hardware-specific.

**Reason**: ROCm installation varies by GPU model and requires manual configuration.

### 10. Repository Cloning

```bash
mkdir -p ~/hypernode
cd ~/hypernode

git clone https://github.com/Hypernode-sol/hypernode-backend.git
git clone https://github.com/Hypernode-sol/hypernode-node-client.git
git clone https://github.com/Hypernode-sol/hypernode-sdk-python.git
```

Clones required repositories to `~/hypernode/`.

**Duration**: 1-2 minutes

### 11. Backend Setup (Validator/Full only)

```bash
cd ~/hypernode/hypernode-backend
npm install

# Create .env
cat > .env <<EOF
NODE_ENV=production
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hypernode
DB_USER=hypernode_user
DB_PASSWORD=<generated>
REDIS_HOST=localhost
REDIS_PORT=6379
SOLANA_RPC_URL=https://devnet.helius-rpc.com/?api-key=ff977ada-bd04-4148-bd39-7887b3e34ce9
EOF

# Create database
sudo -u postgres psql -c "CREATE USER hypernode_user WITH PASSWORD '<generated>';"
sudo -u postgres psql -c "CREATE DATABASE hypernode OWNER hypernode_user;"

# Run migrations
npm run db:migrate
```

**Duration**: 3-5 minutes

**Security**:
- Database password is randomly generated (25 characters)
- Password stored only in `.env` file

### 12. Worker Setup (Worker/Full only)

```bash
cd ~/hypernode/hypernode-node-client
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create .env
cat > .env <<EOF
BACKEND_URL=https://api.hypernodesolana.org
WALLET_PUBKEY=YOUR_WALLET_ADDRESS_HERE
NODE_TOKEN=YOUR_NODE_TOKEN_HERE
GPU_MODEL=auto-detect
REGION=auto-detect
LOG_LEVEL=info
EOF
```

**Duration**: 3-5 minutes

**Note**: User must edit `.env` to add wallet address and node token.

### 13. Post-Installation Summary

Script displays:
- ✅ Components installed
- 📋 Next steps for the selected role
- ⚠️ Reboot requirement (if GPU drivers installed)
- 📖 Links to documentation and support

## Total Installation Time

| Role | Without GPU | With NVIDIA GPU |
|------|-------------|-----------------|
| Worker | 15-20 min | 20-30 min |
| Validator | 20-25 min | N/A |
| Full | 25-35 min | 35-45 min |

**Factors**:
- Internet speed (downloads ~2-5GB)
- System performance
- Existing packages installed

## Verification

### Check Installation

#### Worker Node
```bash
# Check Python environment
cd ~/hypernode/hypernode-node-client
source venv/bin/activate
python --version  # Should show 3.11.x

# Check dependencies
pip list | grep -E "(requests|structlog|pybreaker)"

# Check GPU (NVIDIA)
nvidia-smi
```

#### Validator Node
```bash
# Check Node.js
node --version  # Should show v20.x

# Check PostgreSQL
sudo systemctl status postgresql
psql -U hypernode_user -d hypernode -c "SELECT version();"

# Check Redis
redis-cli ping  # Should return "PONG"

# Check backend
cd ~/hypernode/hypernode-backend
npm run test
```

### Start Services

#### Worker Node
```bash
cd ~/hypernode/hypernode-node-client
source venv/bin/activate

# Edit config first
nano .env

# Start worker
python src/main.py
```

Expected output:
```
INFO     | Hypernode Worker starting...
INFO     | GPU detected: NVIDIA GeForce RTX 3090
INFO     | Connecting to backend: https://api.hypernodesolana.org
INFO     | Heartbeat sent successfully
INFO     | Waiting for jobs...
```

#### Validator Node
```bash
cd ~/hypernode/hypernode-backend

# Start backend
npm start
```

Expected output:
```
info: Hypernode Backend starting...
info: Database connected (PostgreSQL 15)
info: Redis connected
info: WebSocket server listening on port 3000
info: Backend ready - http://localhost:3000
```

Test API:
```bash
curl http://localhost:3000/health
# Expected: {"status":"ok","uptime":12.34}
```

## Troubleshooting

### Script Fails Immediately

**Error**: "Do not run this script as root"
- **Cause**: Running with `sudo ./install.sh`
- **Fix**: Run as normal user: `./install.sh --role worker`

**Error**: "No internet connection detected"
- **Cause**: Cannot reach `google.com`
- **Fix**: Check network: `ping google.com`

**Error**: "Unsupported OS"
- **Cause**: Not Ubuntu or `/etc/os-release` missing
- **Fix**: Use Ubuntu 20.04+ or install manually

### Docker Installation Fails

**Error**: "Failed to install Docker"
- **Check**: `curl https://get.docker.com`
- **Manual**: Follow https://docs.docker.com/engine/install/ubuntu/

**Error**: "Cannot connect to Docker daemon"
- **Cause**: User not in `docker` group
- **Fix**: Logout and login again, or run `newgrp docker`

### Node.js Installation Fails

**Error**: "Failed to add Node.js repository"
- **Check**: `curl https://deb.nodesource.com/setup_20.x`
- **Manual**: Download and install `.deb` from nodejs.org

### PostgreSQL Fails

**Error**: "Database creation failed"
- **Check**: `sudo systemctl status postgresql`
- **Manual**:
  ```bash
  sudo -u postgres psql
  CREATE DATABASE hypernode;
  CREATE USER hypernode_user WITH PASSWORD 'newpassword';
  GRANT ALL PRIVILEGES ON DATABASE hypernode TO hypernode_user;
  ```

### NVIDIA Driver Issues

**Error**: "No NVIDIA GPU detected"
- **Check**: `lspci | grep -i nvidia`
- **Cause**: No NVIDIA GPU or not properly seated

**Error**: "NVIDIA driver installation failed"
- **Check**: `ubuntu-drivers devices`
- **Manual**: `sudo ubuntu-drivers autoinstall`

**After reboot, `nvidia-smi` fails**:
- **Check**: `dmesg | grep -i nvidia`
- **Possible**: Secure Boot enabled (disable in BIOS)

### Python Dependencies Fail

**Error**: "Failed to install worker dependencies"
- **Check**: `python3.11 --version`
- **Fix**: Upgrade pip: `python3.11 -m pip install --upgrade pip`
- **Retry**: `pip install -r requirements.txt -v`

## Uninstallation

Remove Hypernode completely:

```bash
# Stop services
sudo systemctl stop postgresql redis-server docker

# Remove Hypernode directory
rm -rf ~/hypernode

# Remove Docker (optional)
sudo apt remove --purge docker docker-engine docker.io containerd runc
sudo apt autoremove

# Remove NVIDIA drivers (optional)
sudo apt remove --purge nvidia-*
sudo apt autoremove

# Remove databases (optional)
sudo apt remove --purge postgresql* redis-server
```

## Security Considerations

### Script Safety
- ✅ Checks for root execution (rejects)
- ✅ Uses `sudo` only when necessary
- ✅ Validates downloads with checksums (Docker, Node.js)
- ✅ Generates random passwords
- ✅ Does NOT expose private keys

### Post-Installation Security
- 🔒 Change default database password
- 🔒 Configure firewall: `sudo ufw enable && sudo ufw allow 3000/tcp`
- 🔒 Store wallet private keys in hardware wallet
- 🔒 Enable automatic security updates
- 🔒 Use SSH key authentication (disable password login)

## Advanced Usage

### Custom Database Password

```bash
# Edit install.sh before running
DB_PASSWORD="your_custom_secure_password_here"
```

### Custom Installation Directory

```bash
# Change in install.sh
INSTALL_DIR="$HOME/custom-hypernode"
```

### Headless Installation (No user input)

```bash
# Set environment variables
export ROLE=worker
export GPU_TYPE=nvidia

# Run script
./install.sh --role $ROLE --gpu $GPU_TYPE
```

### Behind Corporate Proxy

```bash
# Set proxy before running
export http_proxy="http://proxy.company.com:8080"
export https_proxy="http://proxy.company.com:8080"

./install.sh --role worker
```

## Support

If installation fails:

1. Check logs: `journalctl -xe`
2. Check script output (verbose mode coming soon)
3. Open GitHub issue with:
   - Ubuntu version: `lsb_release -a`
   - Error message
   - Output of failed command

**Channels**:
- **GitHub Issues**: https://github.com/Hypernode-sol/Setup-for-Ubuntu/issues
- **Discord**: https://discord.gg/hypernode
- **Email**: contact@hypernodesolana.org

## License

MIT License - See LICENSE file for details.
