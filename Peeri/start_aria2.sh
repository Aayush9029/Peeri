#!/bin/bash

# Script to download and start aria2c

# Check if aria2c is installed
if ! command -v aria2c &> /dev/null; then
    echo "aria2c is not installed. Installing via Homebrew..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi
    
    # Install aria2
    brew install aria2
    
    if [ $? -ne 0 ]; then
        echo "Failed to install aria2. Please install it manually."
        exit 1
    fi
    
    echo "aria2 installed successfully."
fi

# Create config directory if it doesn't exist
mkdir -p ~/.aria2

# Create a basic config file if it doesn't exist
if [ ! -f ~/.aria2/aria2.conf ]; then
    cat > ~/.aria2/aria2.conf << EOL
# Basic configuration file for Aria2

# Downloads directory
dir=${HOME}/Downloads

# Enable JSON-RPC server
enable-rpc=true
rpc-listen-all=true
rpc-listen-port=6800
rpc-secret=peeri

# BitTorrent settings
bt-enable-lpd=true
bt-max-peers=50
bt-request-peer-speed-limit=100K
enable-peer-exchange=true

# Connection settings
max-concurrent-downloads=5
max-connection-per-server=10
max-overall-download-limit=0
max-overall-upload-limit=50K
min-split-size=1M
split=10

# Other settings
check-integrity=true
continue=true
EOL

    echo "Created default configuration file at ~/.aria2/aria2.conf"
fi

# Kill any existing aria2c processes
pkill -f aria2c

# Start aria2c in the background
aria2c --conf-path=$HOME/.aria2/aria2.conf &

echo "aria2c started with RPC server enabled on port 6800"