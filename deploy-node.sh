#!/bin/bash
# This script builds your custom node, deploys it to your n8n custom nodes folder,
# kills any running n8n process, and then restarts n8n.
#
# It dynamically determines the target directory based on the "name" field in package.json.
#
# Usage: ./deploy-node.sh [target_directory]

# Exit immediately if a command fails.
set -e

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

##############################
# Step 0: Get Package Name and Set Target Directory
##############################
# Use Node.js to extract the package name from package.json.
PACKAGE_NAME=$(node -p "require('./package.json').name")

if [ -z "$PACKAGE_NAME" ]; then
  echo -e "${RED}Error: Could not determine package name from package.json.${NC}"
  exit 1
fi

# Set the target directory based on the package name or command line argument
if [ -n "$1" ]; then
  # If a command line argument is provided, use it as the base directory
  TARGET_DIR="$1/$PACKAGE_NAME"
else
  # Otherwise use the default path
  TARGET_DIR="/home/datproto/apps/n8n/n8n_data/custom/$PACKAGE_NAME"
fi

echo -e "${YELLOW}Detected package name: '$PACKAGE_NAME'${NC}"
echo -e "${YELLOW}Target deployment directory: '$TARGET_DIR'${NC}"

##############################
# Step 1: Build the Node
##############################
echo -e "${YELLOW}Building the node...${NC}"
pnpm run build

if [ $? -ne 0 ]; then
  echo -e "${RED}Build failed. Please fix the errors and try again.${NC}"
  exit 1
fi

##############################
# Step 2: Deploy the Build Output
##############################
# Define the source (build output) directory.
SOURCE_DIR="./dist"

echo -e "${YELLOW}Deploying build output from '$SOURCE_DIR' to '$TARGET_DIR'...${NC}"

# Remove any previous deployment and recreate the target directory.
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to create target directory. Please check permissions.${NC}"
  exit 1
fi

# Copy all files from the build output to the target directory.
cp -r "$SOURCE_DIR/"* "$TARGET_DIR/"

if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to copy files. Please check permissions.${NC}"
  exit 1
fi

echo -e "${GREEN}Deployment complete.${NC}"

##############################
# Step 3: Restart n8n
##############################
echo -e "${YELLOW}Restarting n8n...${NC}"

# Check if Docker is running and if the n8n container exists
if command -v docker &> /dev/null && docker ps -a | grep -q n8n; then
  docker container restart n8n

  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to restart n8n container. Please restart it manually.${NC}"
  else
    echo -e "${GREEN}n8n container restarted successfully.${NC}"

    # Ask if the user wants to see the logs
    read -p "Do you want to see the n8n logs? (y/n): " VIEW_LOGS
    if [[ $VIEW_LOGS == "y" || $VIEW_LOGS == "Y" ]]; then
      docker logs -f n8n
    fi
  fi
else
  echo -e "${YELLOW}Docker or n8n container not found. Please restart n8n manually.${NC}"
fi