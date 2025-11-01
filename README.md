# Hypernode Setup Guide for Ubuntu

> **Complete guide for setting up Hypernode GPU compute nodes on Ubuntu Linux**

This repository provides step-by-step instructions for setting up Hypernode on Ubuntu systems, whether you're running a GPU provider node or developing on the Hypernode platform.

![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-orange)
![Docker](https://img.shields.io/badge/Docker-Required-blue)
![NVIDIA](https://img.shields.io/badge/NVIDIA-GPU-green)

---

## 🎯 What is Hypernode?

Hypernode is a decentralized GPU compute marketplace on Solana blockchain. It connects:
- **GPU Providers**: Earn HYPER tokens by sharing idle GPU resources
- **Compute Users**: Access affordable GPU power for AI, rendering, and compute tasks

**Main Website**: [hypernodesolana.org](https://hypernodesolana.org)

---

## 📋 Table of Contents

1. [System Requirements](#system-requirements)
2. [Quick Start (GPU Provider)](#quick-start-gpu-provider)
3. [Detailed Setup](#detailed-setup)
4. [Development Environment Setup](#development-environment-setup)
5. [Troubleshooting](#troubleshooting)
6. [Resources](#resources)

---

## 💻 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04 LTS or newer (22.04 LTS recommended)
- **CPU**: 4+ cores
- **RAM**: 8 GB minimum (16 GB recommended)
- **Storage**: 50 GB available space
- **Network**: Stable internet connection (100 Mbps+ recommended)

### For GPU Providers
- **GPU**: NVIDIA GPU with CUDA support
  - Compute Capability 3.5+
  - 4 GB+ VRAM (8 GB+ recommended)
  - Supported: RTX series, GTX 1060+, Tesla, A-series
- **Driver**: NVIDIA Driver 450.80.02+ (Latest recommended)
- **CUDA**: 11.0+ (installed via Docker)

### For CPU-Only Nodes
- CPU nodes are supported but earn less than GPU nodes
- Minimum 8 cores recommended

---

## 🚀 Quick Start (GPU Provider)

### Step 1: Install Docker

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in, then verify
docker --version
```

### Step 2: Install NVIDIA Container Toolkit

```bash
# Add NVIDIA package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install NVIDIA Container Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Restart Docker
sudo systemctl restart docker
```

### Step 3: Verify GPU Access

```bash
# Test NVIDIA Docker integration
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi

# You should see your GPU(s) listed
```

### Step 4: Get Your Node Token

1. Visit [hypernodesolana.org/app](https://hypernodesolana.org/app)
2. Connect your Solana wallet (Phantom, Solflare, etc.)
3. Navigate to "Provider" section
4. Generate your node token
5. Copy the full Docker command provided

### Step 5: Run Your Node

```bash
# Example command (replace with your actual token from the app)
docker run -d \
  --name hypernode-host \
  --restart unless-stopped \
  --gpus all \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e HN_NODE_TOKEN=your-token-here \
  ghcr.io/hypernode-sol/host:latest
```

### Step 6: Monitor Your Node

```bash
# View logs
docker logs -f hypernode-host

# Check GPU usage
docker exec hypernode-host nvidia-smi

# Check earnings on the dashboard
# Visit: hypernodesolana.org/app
```

**Congratulations! 🎉** You're now earning HYPER tokens!

---

## 🔧 Detailed Setup

### Installing NVIDIA Drivers

If you don't have NVIDIA drivers installed:

```bash
# Check current driver
nvidia-smi

# If not installed, install latest driver
sudo apt update
sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers autoinstall

# Or install specific version
sudo apt install -y nvidia-driver-535

# Reboot
sudo reboot

# Verify after reboot
nvidia-smi
```

### Firewall Configuration

```bash
# Allow Docker traffic
sudo ufw allow 2376/tcp
sudo ufw allow 2377/tcp
sudo ufw allow 7946/tcp
sudo ufw allow 7946/udp
sudo ufw allow 4789/udp

# Reload firewall
sudo ufw reload
```

### System Optimization for GPU Workloads

```bash
# Set GPU performance mode
sudo nvidia-smi -pm 1

# Set maximum power limit (adjust for your card)
sudo nvidia-smi -pl 300

# Enable persistence mode
sudo nvidia-smi -pm ENABLED
```

### Setting Up Auto-Start on Boot

The Docker container already has `--restart unless-stopped`, but to ensure Docker starts on boot:

```bash
sudo systemctl enable docker
```

---

## 🛠️ Development Environment Setup

### For Backend Development

```bash
# Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node --version
npm --version

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install Redis
sudo apt install -y redis-server

# Clone the main repository
git clone https://github.com/Hypernode-sol/Hypernode-Site-App.git
cd Hypernode-Site-App

# Install dependencies
npm install
cd api
npm install

# Setup environment
cp .env.example .env
# Edit .env with your configuration

# Initialize database
npm run db:init

# Start development servers
npm run dev  # Frontend
cd api && npm run dev  # Backend
```

### For Smart Contract Development

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Install Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

# Add to PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Verify
solana --version

# Install Anchor
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
avm install latest
avm use latest

# Verify
anchor --version

# Clone smart contracts
git clone https://github.com/Hypernode-sol/hypernode-core-protocol.git
cd hypernode-core-protocol

# Build
anchor build

# Test
anchor test
```

### For Python Development (Node Client)

```bash
# Install Python 3.10+
sudo apt install -y python3 python3-pip python3-venv

# Clone node client
git clone https://github.com/Hypernode-sol/hypernode-node-client.git
cd hypernode-node-client

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run tests
python -m pytest
```

---

## 🐛 Troubleshooting

### GPU Not Detected

**Problem**: `nvidia-smi` not working

**Solution**:
```bash
# Check if NVIDIA kernel modules are loaded
lsmod | grep nvidia

# If not loaded, reinstall driver
sudo apt purge nvidia-*
sudo apt autoremove
sudo ubuntu-drivers autoinstall
sudo reboot
```

### Docker Permission Denied

**Problem**: `Got permission denied while trying to connect to the Docker daemon socket`

**Solution**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker
```

### NVIDIA Container Toolkit Issues

**Problem**: `could not select device driver "" with capabilities: [[gpu]]`

**Solution**:
```bash
# Reinstall NVIDIA Container Toolkit
sudo apt-get install --reinstall nvidia-container-toolkit

# Restart Docker
sudo systemctl restart docker

# Test again
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### Node Not Receiving Jobs

**Problem**: Node is online but no jobs assigned

**Possible Causes**:
1. Low reputation score (complete more jobs to improve)
2. Insufficient HYPER stake
3. GPU specs don't match job requirements
4. High competition in your region

**Solutions**:
- Stake HYPER tokens to increase priority
- Improve uptime and job completion rate
- Check node status on dashboard
- Check GitHub Issues for troubleshooting

### Out of Memory Errors

**Problem**: Jobs failing with OOM errors

**Solution**:
```bash
# Check VRAM usage
nvidia-smi

# If consistently hitting limits, you may need to:
# 1. Close other GPU applications
# 2. Reduce concurrent job limit
# 3. Upgrade to GPU with more VRAM
```

---

## 📚 Resources

### Official Links
- **Website**: [hypernodesolana.org](https://hypernodesolana.org)
- **App Dashboard**: [hypernodesolana.org/app](https://hypernodesolana.org/app)
- **GitHub Organization**: [github.com/Hypernode-sol](https://github.com/Hypernode-sol)
- **Twitter**: [@hypernode_sol](https://twitter.com/hypernode_sol)

### Documentation
- [Main Repository](https://github.com/Hypernode-sol/Hypernode-Site-App)
- [Smart Contracts](https://github.com/Hypernode-sol/hypernode-core-protocol)
- [Node Client](https://github.com/Hypernode-sol/hypernode-node-client)
- [Automation Engine](https://github.com/Hypernode-sol/hypernode-automation-engine)

### Community
- **Twitter**: Follow for updates
- **GitHub Discussions**: Ask technical questions
- **Email**: contact@hypernodesolana.org

### Learning Resources
- [Docker Documentation](https://docs.docker.com/)
- [NVIDIA CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit)
- [Solana Documentation](https://docs.solana.com/)
- [Anchor Framework](https://www.anchor-lang.com/)

---

## 🔐 Security Best Practices

### For GPU Providers

1. **Keep your system updated**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Use firewall**:
   ```bash
   sudo ufw enable
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow ssh
   ```

3. **Monitor resource usage**:
   ```bash
   # Install monitoring tools
   sudo apt install -y htop nvtop

   # Monitor GPU
   watch -n 1 nvidia-smi

   # Monitor CPU/RAM
   htop
   ```

4. **Backup your wallet keys** (never share your private keys!)

5. **Review jobs before execution** (if running in manual mode)

---

## 💰 Maximizing Earnings

### Tips for GPU Providers

1. **Maintain High Uptime**
   - Use `--restart unless-stopped` (included in quick start)
   - Monitor node regularly
   - Ensure stable internet connection

2. **Stake HYPER Tokens**
   - Higher stake = higher priority
   - Stake on the dashboard

3. **Optimize GPU Performance**
   - Keep drivers updated
   - Enable performance mode
   - Ensure adequate cooling

4. **Complete Jobs Quickly and Reliably**
   - Fast execution improves reputation
   - Reliable completion increases job assignments

5. **Run Multiple GPUs**
   - Scale horizontally for more earnings
   - Each GPU can be a separate node

---

## 🆘 Getting Help

### Before Asking for Help

1. Check the [Troubleshooting](#troubleshooting) section
2. Review logs: `docker logs hypernode-host`
3. Verify system meets [requirements](#system-requirements)

### Support Channels

- **GitHub Issues**: [Report bugs](https://github.com/Hypernode-sol/Hypernode-Site-App/issues)
- **GitHub Discussions**: Technical questions and support
- **Twitter**: @hypernode_sol for announcements
- **Email**: contact@hypernodesolana.org

---

## 📝 Contributing

Interested in improving this guide?

1. Fork this repository
2. Make your improvements
3. Submit a pull request

All contributions are welcome!

---

## 📄 License

MIT License - see LICENSE file for details

---

## 🌟 Join the Hypernode Network!

Start earning HYPER tokens today by sharing your GPU power with the world.

**Get started now**: [hypernodesolana.org/app](https://hypernodesolana.org/app)

---

**Last Updated**: 2025-11-01
**Version**: 1.0.0
**Maintained by**: Hypernode Solana Team
