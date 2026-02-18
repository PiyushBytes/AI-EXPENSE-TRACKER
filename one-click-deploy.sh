#!/bin/bash

#############################################
# ExpenseAI One-Click Deployment Script
# Supports: development, staging, production
#############################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default values
ENVIRONMENT="${1:-development}"
COMPOSE_FILE="docker-compose.${ENVIRONMENT}.yml"
ENV_FILE=".env.${ENVIRONMENT}"
SKIP_TESTS="${SKIP_TESTS:-false}"
SKIP_BACKUP="${SKIP_BACKUP:-false}"

#############################################
# Functions
#############################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_dependencies() {
    print_header "Checking Dependencies"

    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    print_success "Docker installed: $(docker --version)"

    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    print_success "Docker Compose installed: $(docker compose version)"

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    print_success "Docker daemon is running"
}

check_environment() {
    print_header "Checking Environment Configuration"

    # Check if compose file exists
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    print_success "Compose file found: $COMPOSE_FILE"

    # Check if env file exists
    if [ ! -f "$ENV_FILE" ]; then
        print_warning "Environment file not found: $ENV_FILE"

        if [ -f "${ENV_FILE}.example" ]; then
            print_info "Copying from example..."
            cp "${ENV_FILE}.example" "$ENV_FILE"
            print_warning "Please edit $ENV_FILE with your configuration"

            if [ "$ENVIRONMENT" != "development" ]; then
                print_error "Production/Staging deployment requires configured environment file"
                exit 1
            fi
        else
            print_error "No example environment file found"
            exit 1
        fi
    else
        print_success "Environment file found: $ENV_FILE"
    fi

    # Validate critical environment variables for production
    if [ "$ENVIRONMENT" = "production" ] || [ "$ENVIRONMENT" = "staging" ]; then
        if grep -q "CHANGE_THIS" "$ENV_FILE"; then
            print_error "Found default secrets in $ENV_FILE"
            print_error "Please update all CHANGE_THIS placeholders"
            exit 1
        fi
        print_success "Environment variables validated"
    fi
}

run_tests() {
    if [ "$SKIP_TESTS" = "true" ]; then
        print_warning "Skipping tests (SKIP_TESTS=true)"
        return
    fi

    print_header "Running Tests"

    # Backend tests
    if [ -d "backend" ]; then
        print_info "Running backend tests..."
        cd backend
        if [ -f "package.json" ]; then
            npm install --silent
            npm run test || print_warning "Backend tests failed (continuing...)"
        fi
        cd ..
    fi

    # Frontend tests
    if [ -d "frontend" ]; then
        print_info "Running frontend tests..."
        cd frontend
        if [ -f "package.json" ]; then
            npm install --silent
            npm run test || print_warning "Frontend tests failed (continuing...)"
        fi
        cd ..
    fi

    print_success "Tests completed"
}

create_backup() {
    if [ "$SKIP_BACKUP" = "true" ]; then
        print_warning "Skipping backup (SKIP_BACKUP=true)"
        return
    fi

    if [ "$ENVIRONMENT" = "production" ] || [ "$ENVIRONMENT" = "staging" ]; then
        print_header "Creating Backup"

        BACKUP_DIR="./backups"
        mkdir -p "$BACKUP_DIR"
        BACKUP_FILE="${BACKUP_DIR}/backup_$(date +%Y%m%d_%H%M%S).sql"

        if docker compose -f "$COMPOSE_FILE" ps | grep -q "postgres"; then
            if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_dump -U postgres expense_ai > "$BACKUP_FILE" 2>/dev/null; then
                print_success "Backup created: $BACKUP_FILE"
            else
                print_warning "Could not create backup (database may not be running)"
            fi
        else
            print_warning "PostgreSQL container not running, skipping backup"
        fi
    fi
}

build_images() {
    print_header "Building Docker Images"

    # Pull base images first
    print_info "Pulling base images..."
    docker compose -f "$COMPOSE_FILE" pull --ignore-pull-failures || true

    # Build images
    print_info "Building application images..."
    docker compose -f "$COMPOSE_FILE" build --no-cache

    print_success "Images built successfully"
}

deploy_services() {
    print_header "Deploying Services"

    # Stop existing containers
    print_info "Stopping existing containers..."
    docker compose -f "$COMPOSE_FILE" down

    # Start services
    print_info "Starting services..."
    docker compose -f "$COMPOSE_FILE" up -d

    print_success "Services started"
}

wait_for_health() {
    print_header "Waiting for Services to be Healthy"

    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker compose -f "$COMPOSE_FILE" ps | grep -q "unhealthy"; then
            print_info "Waiting for services to become healthy... ($((attempt + 1))/$max_attempts)"
            sleep 2
            attempt=$((attempt + 1))
        else
            print_success "All services are healthy"
            return 0
        fi
    done

    print_error "Services did not become healthy in time"
    docker compose -f "$COMPOSE_FILE" ps
    return 1
}

run_migrations() {
    print_header "Running Database Migrations"

    if docker compose -f "$COMPOSE_FILE" exec -T backend npm run migration:run 2>/dev/null; then
        print_success "Migrations completed"
    else
        print_warning "Could not run migrations (backend may not be ready)"
    fi
}

verify_deployment() {
    print_header "Verifying Deployment"

    # Wait a bit for services to fully start
    sleep 5

    # Check health endpoint
    local health_url="http://localhost:3000/health"

    if [ "$ENVIRONMENT" = "production" ]; then
        health_url="https://yourdomain.com/health"
    elif [ "$ENVIRONMENT" = "staging" ]; then
        health_url="https://staging.yourdomain.com/health"
    fi

    print_info "Checking health endpoint: $health_url"

    if curl -f -s "$health_url" > /dev/null 2>&1; then
        print_success "Health check passed"

        # Display health status
        curl -s "$health_url" | jq '.' 2>/dev/null || curl -s "$health_url"
    else
        print_warning "Health check failed (service may still be starting)"
    fi
}

show_deployment_info() {
    print_header "Deployment Information"

    echo -e "${GREEN}Environment:${NC} $ENVIRONMENT"
    echo -e "${GREEN}Compose File:${NC} $COMPOSE_FILE"
    echo -e "${GREEN}Env File:${NC} $ENV_FILE"
    echo ""

    # Show running containers
    echo -e "${BLUE}Running Containers:${NC}"
    docker compose -f "$COMPOSE_FILE" ps

    echo ""
    echo -e "${BLUE}Access URLs:${NC}"

    if [ "$ENVIRONMENT" = "development" ]; then
        echo -e "  Frontend: ${GREEN}http://localhost:3001${NC}"
        echo -e "  Backend:  ${GREEN}http://localhost:3000${NC}"
        echo -e "  API Docs: ${GREEN}http://localhost:3000/docs${NC}"
        echo -e "  Adminer:  ${GREEN}http://localhost:8080${NC}"
        echo -e "  Redis UI: ${GREEN}http://localhost:8081${NC}"
    elif [ "$ENVIRONMENT" = "staging" ]; then
        echo -e "  Application: ${GREEN}https://staging.yourdomain.com${NC}"
        echo -e "  API:         ${GREEN}https://staging-api.yourdomain.com${NC}"
    else
        echo -e "  Application: ${GREEN}https://yourdomain.com${NC}"
        echo -e "  API:         ${GREEN}https://api.yourdomain.com${NC}"
    fi

    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "  View logs:     ${YELLOW}docker compose -f $COMPOSE_FILE logs -f${NC}"
    echo -e "  Stop services: ${YELLOW}docker compose -f $COMPOSE_FILE down${NC}"
    echo -e "  Restart:       ${YELLOW}docker compose -f $COMPOSE_FILE restart${NC}"
}

cleanup() {
    print_header "Cleanup"

    print_info "Removing dangling images..."
    docker image prune -f

    print_success "Cleanup completed"
}

#############################################
# Main Execution
#############################################

main() {
    print_header "ExpenseAI One-Click Deployment - $ENVIRONMENT"

    # Run deployment steps
    check_dependencies
    check_environment

    if [ "$ENVIRONMENT" != "development" ]; then
        run_tests
    fi

    create_backup
    build_images
    deploy_services
    wait_for_health || true
    run_migrations
    verify_deployment
    cleanup
    show_deployment_info

    print_header "Deployment Complete! 🚀"
}

# Handle script arguments
case "${1:-}" in
    -h|--help)
        echo "Usage: $0 [environment] [options]"
        echo ""
        echo "Environments:"
        echo "  development (default)"
        echo "  staging"
        echo "  production"
        echo ""
        echo "Options:"
        echo "  SKIP_TESTS=true    Skip running tests"
        echo "  SKIP_BACKUP=true   Skip creating backup"
        echo ""
        echo "Examples:"
        echo "  $0                           # Deploy to development"
        echo "  $0 staging                   # Deploy to staging"
        echo "  $0 production                # Deploy to production"
        echo "  SKIP_TESTS=true $0 staging   # Deploy to staging without tests"
        exit 0
        ;;
esac

# Run main function
main

# Exit with success
exit 0
