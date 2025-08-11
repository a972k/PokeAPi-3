#!/bin/bash
# =============================================================================
# PokeAPI Backend Deployment Script
# =============================================================================
# Easy deployment script for different environments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
ACTION="up"
BUILD_FLAG=""
DETACH_FLAG=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show help
show_help() {
    cat << EOF
PokeAPI Backend Deployment Script

Usage: $0 [OPTIONS] [ACTION]

ACTIONS:
    up              Start services (default)
    down            Stop services
    restart         Restart services
    logs            Show logs
    status          Show service status
    build           Build images
    clean           Clean up containers and volumes

OPTIONS:
    -e, --env ENV       Environment: dev, prod (default: dev)
    -d, --detach        Run in detached mode (background)
    -b, --build         Build images before starting
    -h, --help          Show this help message

EXAMPLES:
    # Start development environment
    $0

    # Start production environment in background
    $0 --env prod --detach up

    # Build and start development with logs
    $0 --build --env dev up

    # Stop production environment
    $0 --env prod down

    # View logs for development
    $0 --env dev logs

    # Clean up everything
    $0 clean

ENVIRONMENT FILES:
    Development: .env.dev
    Production:  .env.prod (copy from .env.prod.template)

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -d|--detach)
            DETACH_FLAG="-d"
            shift
            ;;
        -b|--build)
            BUILD_FLAG="--build"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        up|down|restart|logs|status|build|clean)
            ACTION="$1"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Use 'dev' or 'prod'"
    exit 1
fi

# Set compose files based on environment
if [[ "$ENVIRONMENT" == "dev" ]]; then
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.dev.yml"
    ENV_FILE=".env.dev"
elif [[ "$ENVIRONMENT" == "prod" ]]; then
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
    ENV_FILE=".env.prod"
fi

# Check if environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
    if [[ "$ENVIRONMENT" == "prod" && -f ".env.prod.template" ]]; then
        print_warning "Production environment file not found. Please copy .env.prod.template to .env.prod and customize it."
        print_status "Running: cp .env.prod.template .env.prod"
        cp .env.prod.template .env.prod
        print_warning "Please edit .env.prod with secure passwords and keys before proceeding!"
        exit 1
    else
        print_error "Environment file not found: $ENV_FILE"
        exit 1
    fi
fi

# Build docker-compose command
DOCKER_COMPOSE_CMD="docker-compose --env-file $ENV_FILE $COMPOSE_FILES"

print_status "Environment: $ENVIRONMENT"
print_status "Action: $ACTION"
print_status "Compose files: $COMPOSE_FILES"
print_status "Environment file: $ENV_FILE"

# Execute the requested action
case $ACTION in
    up)
        print_status "Starting services..."
        $DOCKER_COMPOSE_CMD up $BUILD_FLAG $DETACH_FLAG
        if [[ -n "$DETACH_FLAG" ]]; then
            print_success "Services started in background"
            print_status "View logs with: $0 --env $ENVIRONMENT logs"
            print_status "Check status with: $0 --env $ENVIRONMENT status"
        fi
        ;;
    down)
        print_status "Stopping services..."
        $DOCKER_COMPOSE_CMD down
        print_success "Services stopped"
        ;;
    restart)
        print_status "Restarting services..."
        $DOCKER_COMPOSE_CMD restart
        print_success "Services restarted"
        ;;
    logs)
        print_status "Showing logs..."
        $DOCKER_COMPOSE_CMD logs -f
        ;;
    status)
        print_status "Service status:"
        $DOCKER_COMPOSE_CMD ps
        echo ""
        print_status "Health status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep pokeapi || true
        ;;
    build)
        print_status "Building images..."
        $DOCKER_COMPOSE_CMD build --no-cache
        print_success "Images built successfully"
        ;;
    clean)
        print_warning "This will remove all containers, volumes, and networks!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Cleaning up..."
            $DOCKER_COMPOSE_CMD down -v --remove-orphans
            docker system prune -f
            print_success "Cleanup completed"
        else
            print_status "Cleanup cancelled"
        fi
        ;;
    *)
        print_error "Unknown action: $ACTION"
        show_help
        exit 1
        ;;
esac

print_success "Operation completed successfully!"

# Show useful endpoints for up action
if [[ "$ACTION" == "up" && -n "$DETACH_FLAG" ]]; then
    echo ""
    print_status "API Endpoints:"
    echo "  Health Check: http://localhost:5000/health"
    echo "  Pokemon API:  http://localhost:5000/pokemon"
    echo "  Swagger UI:   http://localhost:5000/docs (if enabled)"
    echo ""
    print_status "MongoDB:"
    if [[ "$ENVIRONMENT" == "dev" ]]; then
        echo "  Connection: mongodb://localhost:27017/pokeapi_game_dev"
    else
        echo "  Connection: mongodb://admin:password@localhost:27017/pokeapi_game"
    fi
fi
