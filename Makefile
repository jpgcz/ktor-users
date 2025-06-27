# Makefile for Ktor-users application setup

# Default variables
ENVIRONMENT ?= dev
PORT ?= 8081
CONTAINER_NAME = ktor-users-$(ENVIRONMENT)
SERVICE_NAME = ktor-users-$(ENVIRONMENT)

# Set port based on environment if not explicitly provided
ifeq ($(ENVIRONMENT),prod)
  PORT ?= 8082
endif

.PHONY: all install-deps setup-docker build-app run-app create-service check-status clean help

all: install-deps setup-docker build-app run-app create-service check-status

help:
	@echo "Usage: make [target] [ENVIRONMENT=dev|prod] [PORT=port_number]"
	@echo ""
	@echo "Targets:"
	@echo "  all             Run complete setup (default)"
	@echo "  install-deps    Install system dependencies"
	@echo "  setup-docker    Install and configure Docker"
	@echo "  build-app       Build the Ktor application"
	@echo "  run-app         Run the application in Docker"
	@echo "  create-service  Create systemd service for auto-start"
	@echo "  check-status    Check if application is running"
	@echo "  clean           Stop and remove containers"
	@echo "  help            Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  ENVIRONMENT     Set to 'dev' or 'prod' (default: dev)"
	@echo "  PORT           Set custom port (default: 8081 for dev, 8082 for prod)"

install-deps:
	@echo "Installing dependencies..."
	apt-get update
	apt-get upgrade -y
	apt-get install -y openjdk-17-jdk

setup-docker:
	@echo "Setting up Docker..."
	apt-get install -y apt-transport-https ca-certificates curl software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $$(lsb_release -cs) stable"
	apt-get update
	apt-get install -y docker-ce docker-ce-cli containerd.io
	systemctl enable docker
	systemctl start docker
	@if [ -n "$$SUDO_USER" ]; then \
		usermod -aG docker $$SUDO_USER; \
		echo "Added user $$SUDO_USER to docker group"; \
	fi

build-app:
	@echo "Building application for $(ENVIRONMENT) environment..."
	chmod +x ./gradlew
	./gradlew build
	VERSION=$$(grep -o 'version = "[^"]*"' build.gradle.kts 2>/dev/null || grep -o 'version = [^"]*' build.gradle 2>/dev/null | cut -d'"' -f2 || echo "1.0.0")
	docker build -t ktor-users:$$VERSION-$(ENVIRONMENT) .

run-app:
	@echo "Running application container on port $(PORT)..."
	-docker stop $(CONTAINER_NAME) 2>/dev/null || true
	-docker rm $(CONTAINER_NAME) 2>/dev/null || true
	VERSION=$$(grep -o 'version = "[^"]*"' build.gradle.kts 2>/dev/null || grep -o 'version = [^"]*' build.gradle 2>/dev/null | cut -d'"' -f2 || echo "1.0.0")
	docker run -d --name $(CONTAINER_NAME) -p $(PORT):8081 -e ENVIRONMENT=$(ENVIRONMENT) --restart unless-stopped ktor-users:$$VERSION-$(ENVIRONMENT)

create-service:
	@echo "Creating systemd service for $(SERVICE_NAME)..."
	@cat > /etc/systemd/system/$(SERVICE_NAME).service << EOF
[Unit]
Description=Ktor Users Application Container ($(ENVIRONMENT))
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker start $(CONTAINER_NAME)
ExecStop=/usr/bin/docker stop $(CONTAINER_NAME)

[Install]
WantedBy=multi-user.target
EOF
	systemctl enable $(SERVICE_NAME).service

check-status:
	@echo "Checking application status..."
	@sleep 5
	@if curl -s http://localhost:$(PORT)/user > /dev/null; then \
		echo "Application is running successfully!"; \
		echo "You can access the API at http://$$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):$(PORT)/user"; \
	else \
		echo "Application may not be running correctly. Check logs with: docker logs $(CONTAINER_NAME)"; \
	fi

clean:
	@echo "Cleaning up..."
	-docker stop $(CONTAINER_NAME) 2>/dev/null || true
	-docker rm $(CONTAINER_NAME) 2>/dev/null || true
	-systemctl disable $(SERVICE_NAME).service 2>/dev/null || true
	-rm -f /etc/systemd/system/$(SERVICE_NAME).service 2>/dev/null || true
