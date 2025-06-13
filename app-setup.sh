#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
PORT="8081"
CONTAINER_NAME="ktor-users"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--env dev|prod] [--port PORT_NUMBER]"
      exit 1
      ;;
  esac
done

# Set environment-specific values
if [ "$ENVIRONMENT" = "prod" ]; then
  PORT=${PORT:-8082}
  CONTAINER_NAME="ktor-users-prod"
  SERVICE_NAME="ktor-users-prod"
else
  PORT=${PORT:-8081}
  CONTAINER_NAME="ktor-users-dev"
  SERVICE_NAME="ktor-users-dev"
fi

echo -e "${GREEN}Starting Ktor-users application setup for ${ENVIRONMENT} environment on port ${PORT}...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root or with sudo${NC}"
  exit 1
fi

# Update system packages
echo -e "${YELLOW}Updating system packages...${NC}"
apt-get update
apt-get upgrade -y

# Install Java 17
echo -e "${YELLOW}Installing Java 17...${NC}"
apt-get install -y openjdk-17-jdk
java -version

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker

# Add current user to docker group
if [ -n "$SUDO_USER" ]; then
  usermod -aG docker $SUDO_USER
  echo -e "${GREEN}Added user $SUDO_USER to docker group${NC}"
fi

# Check if we're in the application directory
if [ ! -f "build.gradle.kts" ] && [ ! -f "build.gradle" ]; then
  echo -e "${RED}Error: Not in the application directory. Please run this script from the Ktor-users project root.${NC}"
  exit 1
fi

# Build the application with Gradle
echo -e "${YELLOW}Building the application...${NC}"
chmod +x ./gradlew
./gradlew build

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
VERSION=$(grep -o 'version = "[^"]*"' build.gradle.kts 2>/dev/null || grep -o 'version = [^"]*' build.gradle 2>/dev/null | cut -d'"' -f2 || echo "1.0.0")
IMAGE_TAG="ktor-users:${VERSION}-${ENVIRONMENT}"
docker build -t $IMAGE_TAG .

# Stop any existing container
echo -e "${YELLOW}Stopping any existing ${CONTAINER_NAME} containers...${NC}"
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Run the container
echo -e "${YELLOW}Starting the application container...${NC}"
docker run -d --name $CONTAINER_NAME -p $PORT:8081 -e ENVIRONMENT=$ENVIRONMENT --restart unless-stopped $IMAGE_TAG

# Create a systemd service to start the container on boot
echo -e "${YELLOW}Creating systemd service for auto-start...${NC}"
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Ktor Users Application Container ($ENVIRONMENT)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker start $CONTAINER_NAME
ExecStop=/usr/bin/docker stop $CONTAINER_NAME

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable $SERVICE_NAME.service

# Check if the application is running
echo -e "${YELLOW}Checking if the application is running...${NC}"
sleep 5
if curl -s http://localhost:$PORT/user > /dev/null; then
  echo -e "${GREEN}Application is running successfully!${NC}"
  echo -e "${GREEN}You can access the API at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):$PORT/user${NC}"
else
  echo -e "${RED}Application may not be running correctly. Check logs with: docker logs $CONTAINER_NAME${NC}"
fi

echo -e "${GREEN}Setup complete for $ENVIRONMENT environment!${NC}"
echo -e "${YELLOW}To check logs: ${NC}docker logs $CONTAINER_NAME"
echo -e "${YELLOW}To restart the application: ${NC}docker restart $CONTAINER_NAME"
echo -e "${YELLOW}To stop the application: ${NC}docker stop $CONTAINER_NAME"