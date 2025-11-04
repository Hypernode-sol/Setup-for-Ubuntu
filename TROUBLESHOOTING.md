# Troubleshooting Guide

Common issues and solutions when setting up Hypernode on Ubuntu.

## Installation Issues

### apt-get update fails

**Problem**: Package lists can't be updated

**Solution**:
```bash
sudo apt-get clean
sudo apt-get update --fix-missing
```

### Node.js installation fails

**Problem**: nvm or Node.js won't install

**Solution**:
```bash
# Remove existing Node.js
sudo apt-get remove nodejs npm

# Reinstall nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
```

### Permission denied errors

**Problem**: Can't write to directories

**Solution**:
```bash
# Fix npm permissions
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## GPU Issues

### NVIDIA driver not detected

**Problem**: `nvidia-smi` command not found

**Solution**:
```bash
# Check if GPU is detected
lspci | grep -i nvidia

# Install drivers
sudo ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
sudo reboot
```

### CUDA toolkit issues

**Problem**: CUDA libraries not found

**Solution**:
```bash
# Add CUDA to path
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

## Network Issues

### WebSocket connection fails

**Problem**: Node client can't connect to backend

**Solution**:
```bash
# Check if port is open
sudo ufw status
sudo ufw allow 3007

# Test connection
telnet localhost 3007
```

### Firewall blocking connections

**Problem**: External connections blocked

**Solution**:
```bash
# Allow necessary ports
sudo ufw allow 3000  # Frontend
sudo ufw allow 3006  # HTTP API
sudo ufw allow 3007  # WebSocket
sudo ufw enable
```

## Docker Issues

### Docker daemon not running

**Problem**: Cannot connect to Docker daemon

**Solution**:
```bash
# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Container build fails

**Problem**: Docker image won't build

**Solution**:
```bash
# Clean Docker cache
docker system prune -a

# Rebuild with no cache
docker build --no-cache -t hypernode .
```

## Performance Issues

### High CPU usage

**Solution**:
```bash
# Monitor processes
htop

# Limit node client CPU usage
cpulimit -l 50 -p $(pgrep -f node)
```

### Out of memory errors

**Solution**:
```bash
# Check memory usage
free -h

# Add swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## Database Issues

### PostgreSQL connection fails

**Problem**: Can't connect to database

**Solution**:
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Restart PostgreSQL
sudo systemctl restart postgresql

# Check connection
psql -U postgres -d hypernode
```

## Node Client Issues

### Registration token invalid

**Problem**: Token expired or incorrect

**Solution**:
1. Go to https://hypernodesolana.org/app
2. Connect wallet
3. Generate new registration token
4. Update environment variable

### Jobs not being received

**Problem**: Node is online but not getting jobs

**Solution**:
```bash
# Check node status
curl http://localhost:3006/api/nodes

# Restart node client
killall node
npm start
```

## Still Having Issues?

- Check logs: `tail -f ~/.pm2/logs/*.log`
- Review system logs: `journalctl -xe`
- Report issue: https://github.com/Hypernode-sol/Setup-for-Ubuntu/issues
- Email: contact@hypernodesolana.org
