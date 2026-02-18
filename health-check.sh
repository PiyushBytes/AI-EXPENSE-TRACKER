#!/bin/bash

##############################################
# Health Check Script
# Verifies all services are running correctly
##############################################

set -e

ENVIRONMENT="${1:-development}"
COMPOSE_FILE="docker-compose.${ENVIRONMENT}.yml"

echo "🏥 Health Check - $ENVIRONMENT"
echo "==============================="
echo ""

# Check if services are running
echo "📊 Service Status:"
docker compose -f "$COMPOSE_FILE" ps

echo ""
echo "🔍 Detailed Health Checks:"

# Check PostgreSQL
echo -n "  PostgreSQL: "
if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ Healthy"
else
    echo "❌ Unhealthy"
fi

# Check Redis
echo -n "  Redis:      "
if docker compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Healthy"
else
    echo "❌ Unhealthy"
fi

# Check Backend API
echo -n "  Backend:    "
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Healthy"

    # Show detailed health
    echo ""
    echo "📋 Backend Health Details:"
    curl -s http://localhost:3000/health | jq '.' 2>/dev/null || curl -s http://localhost:3000/health
else
    echo "❌ Unhealthy or not responding"
fi

# Check Frontend
echo ""
echo -n "  Frontend:   "
if curl -f -s http://localhost:3001 > /dev/null 2>&1; then
    echo "✅ Healthy"
else
    echo "❌ Unhealthy or not responding"
fi

echo ""
echo "📈 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "✅ Health check complete!"
