#!/bin/bash

# Production Deployment Script for ExpenseAI
# Usage: ./deploy.sh [environment]

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-production}
COMPOSE_FILE="docker-compose.${ENVIRONMENT}.yml"
ENV_FILE=".env.${ENVIRONMENT}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ExpenseAI Production Deployment${NC}"
echo -e "${GREEN}Environment: ${ENVIRONMENT}${NC}"
echo -e "${GREEN}========================================${NC}"

# Pre-deployment checks
echo -e "\n${YELLOW}Running pre-deployment checks...${NC}"

# Check if required files exist
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: ${ENV_FILE} not found!${NC}"
    echo "Please create ${ENV_FILE} from ${ENV_FILE}.example"
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: ${COMPOSE_FILE} not found!${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running!${NC}"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker Compose is not available!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Pre-deployment checks passed${NC}"

# Backup database
echo -e "\n${YELLOW}Creating database backup...${NC}"
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="${BACKUP_DIR}/backup_$(date +%Y%m%d_%H%M%S).sql"

if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_dump -U postgres expense_ai > "$BACKUP_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Database backup created: ${BACKUP_FILE}${NC}"
else
    echo -e "${YELLOW}⚠ Could not create database backup (database may not be running)${NC}"
fi

# Pull latest images
echo -e "\n${YELLOW}Pulling latest Docker images...${NC}"
docker compose -f "$COMPOSE_FILE" pull

# Build images
echo -e "\n${YELLOW}Building Docker images...${NC}"
docker compose -f "$COMPOSE_FILE" build --no-cache

# Stop existing containers
echo -e "\n${YELLOW}Stopping existing containers...${NC}"
docker compose -f "$COMPOSE_FILE" down

# Start services
echo -e "\n${YELLOW}Starting services...${NC}"
docker compose -f "$COMPOSE_FILE" up -d

# Wait for services to be healthy
echo -e "\n${YELLOW}Waiting for services to be healthy...${NC}"
sleep 10

# Check health
echo -e "\n${YELLOW}Checking service health...${NC}"
RETRIES=30
COUNT=0

while [ $COUNT -lt $RETRIES ]; do
    if docker compose -f "$COMPOSE_FILE" ps | grep -q "unhealthy"; then
        echo -e "${YELLOW}Waiting for services to become healthy...${NC}"
        sleep 2
        COUNT=$((COUNT+1))
    else
        echo -e "${GREEN}✓ All services are healthy${NC}"
        break
    fi
done

if [ $COUNT -eq $RETRIES ]; then
    echo -e "${RED}Error: Services did not become healthy in time${NC}"
    docker compose -f "$COMPOSE_FILE" ps
    docker compose -f "$COMPOSE_FILE" logs
    exit 1
fi

# Run database migrations
echo -e "\n${YELLOW}Running database migrations...${NC}"
docker compose -f "$COMPOSE_FILE" exec -T backend npm run migration:run
echo -e "${GREEN}✓ Database migrations completed${NC}"

# Show running containers
echo -e "\n${YELLOW}Running containers:${NC}"
docker compose -f "$COMPOSE_FILE" ps

# Test API endpoint
echo -e "\n${YELLOW}Testing API health endpoint...${NC}"
sleep 5
if curl -f -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✓ API is responding${NC}"
else
    echo -e "${RED}Error: API health check failed${NC}"
    docker compose -f "$COMPOSE_FILE" logs backend
    exit 1
fi

# Cleanup old images
echo -e "\n${YELLOW}Cleaning up old Docker images...${NC}"
docker image prune -f

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nAccess the application at:"
echo -e "  Frontend: ${GREEN}http://localhost${NC}"
echo -e "  API: ${GREEN}http://localhost:3000${NC}"
echo -e "  Health Check: ${GREEN}http://localhost:3000/health${NC}"
echo -e "\nTo view logs:"
echo -e "  ${YELLOW}docker compose -f ${COMPOSE_FILE} logs -f${NC}"
echo -e "\nTo stop services:"
echo -e "  ${YELLOW}docker compose -f ${COMPOSE_FILE} down${NC}"
