#!/bin/bash

#############################################
# Quick Deploy Script - Ultra Simple
# Usage: ./quick-deploy.sh
#############################################

set -e

echo "🚀 ExpenseAI Quick Deploy"
echo "========================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✓ Docker is running"

# Ask for environment if not provided
if [ -z "$1" ]; then
    echo ""
    echo "Select environment:"
    echo "  1) Development (default)"
    echo "  2) Staging"
    echo "  3) Production"
    echo ""
    read -p "Enter choice [1-3]: " choice

    case $choice in
        2) ENV="staging" ;;
        3) ENV="production" ;;
        *) ENV="development" ;;
    esac
else
    ENV="$1"
fi

echo "📦 Environment: $ENV"

# Set compose file
COMPOSE_FILE="docker-compose.${ENV}.yml"

# Check if file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Simple deployment
echo ""
echo "🔨 Building images..."
docker compose -f "$COMPOSE_FILE" build

echo "🚀 Starting services..."
docker compose -f "$COMPOSE_FILE" up -d

echo "⏳ Waiting for services to start..."
sleep 10

echo "🏥 Checking health..."
docker compose -f "$COMPOSE_FILE" ps

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Quick commands:"
echo "  View logs: docker compose -f $COMPOSE_FILE logs -f"
echo "  Stop:      docker compose -f $COMPOSE_FILE down"
echo "  Restart:   docker compose -f $COMPOSE_FILE restart"
echo ""

if [ "$ENV" = "development" ]; then
    echo "🌐 Access at:"
    echo "  Frontend: http://localhost:3001"
    echo "  Backend:  http://localhost:3000"
fi
