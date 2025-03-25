#!/bin/bash

# Set Variables
DELEGATE_NAME="vm-delegate"
ACCOUNT_ID="_Ci0EyZJTDmD1Kc1t_OA_A"
DELEGATE_TOKEN="ZDUwMDU5ODE0OGY0M2QyMGVhZjhlNjY4YzIwOThiNTM="
MANAGER_ENDPOINT="https://app.harness.io"
DELEGATE_DIR="/opt/harness-delegate"
DELEGATE_DOWNLOAD_URL="https://app.harness.io/storage/harness-download/delegate/delegate.tar.gz"

# Update system
echo "Updating system packages..."
sudo apt update -y || sudo yum update -y

# Install required dependencies
echo "Installing required packages..."
sudo apt install -y unzip wget || sudo yum install -y unzip wget

# Create delegate directory
echo "Creating delegate directory..."
sudo mkdir -p $DELEGATE_DIR
cd $DELEGATE_DIR

# Download and extract the delegate
echo "Downloading Harness Delegate..."
wget -O delegate.tar.gz "$DELEGATE_DOWNLOAD_URL"

if [[ $? -ne 0 ]]; then
    echo "Failed to download delegate. Check your network or credentials."
    exit 1
fi

echo "Extracting Delegate..."
sudo tar -xzf delegate.tar.gz -C $DELEGATE_DIR

# Set permissions
echo "Setting permissions..."
sudo chmod +x $DELEGATE_DIR/*.sh

# Configure delegate settings
echo "Configuring Delegate..."
echo "accountId=$ACCOUNT_ID" > $DELEGATE_DIR/config
echo "delegateToken=$DELEGATE_TOKEN" >> $DELEGATE_DIR/config
echo "managerEndpoint=$MANAGER_ENDPOINT" >> $DELEGATE_DIR/config
echo "delegateName=$DELEGATE_NAME" >> $DELEGATE_DIR/config

# Start delegate
echo "Starting Delegate..."
nohup $DELEGATE_DIR/start.sh > $DELEGATE_DIR/delegate.log 2>&1 &

# Check if delegate is running
sleep 10
if pgrep -f "delegate"; then
    echo "Harness Delegate successfully installed and running."
else
    echo "Failed to start Harness Delegate. Check logs at $DELEGATE_DIR/delegate.log"
    exit 1
fi
