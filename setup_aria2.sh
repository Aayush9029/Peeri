#!/bin/bash

# This script ensures aria2 is properly set up for the Peeri app

# Function to print colored messages
print_message() {
  local color=$1
  local message=$2
  
  case $color in
    "green") echo -e "\033[0;32m$message\033[0m" ;;
    "yellow") echo -e "\033[0;33m$message\033[0m" ;;
    "red") echo -e "\033[0;31m$message\033[0m" ;;
    *) echo "$message" ;;
  esac
}

print_message "green" "Setting up aria2 for Peeri..."

# Make the start_aria2.sh script executable
if [ -f "./Peeri/start_aria2.sh" ]; then
  chmod +x ./Peeri/start_aria2.sh
  print_message "green" "✓ Made start_aria2.sh executable"
else
  print_message "red" "✗ Could not find start_aria2.sh in Peeri directory"
  exit 1
fi

# Check if aria2 is installed
if command -v aria2c &> /dev/null; then
  print_message "green" "✓ aria2c is already installed"
else
  print_message "yellow" "! aria2c is not installed"
  
  # Check if Homebrew is installed
  if command -v brew &> /dev/null; then
    print_message "yellow" "Installing aria2 using Homebrew..."
    brew install aria2
    
    if [ $? -eq 0 ]; then
      print_message "green" "✓ aria2 installed successfully"
    else
      print_message "red" "✗ Failed to install aria2 using Homebrew"
      print_message "yellow" "Please install aria2 manually and try again"
      exit 1
    fi
  else
    print_message "red" "✗ Homebrew is not installed"
    print_message "yellow" "Please install Homebrew (https://brew.sh) or aria2 manually"
    exit 1
  fi
fi

# Create .aria2 directory if it doesn't exist
mkdir -p ~/.aria2
print_message "green" "✓ Created ~/.aria2 directory"

# Create configuration file if it doesn't exist
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
  print_message "green" "✓ Created configuration file at ~/.aria2/aria2.conf"
else
  print_message "green" "✓ Configuration file already exists at ~/.aria2/aria2.conf"
fi

print_message "green" "✓ aria2 setup completed successfully"
print_message "yellow" "Note: You still need to ensure start_aria2.sh is included in the app bundle."
print_message "yellow" "See SETUP.md for instructions."