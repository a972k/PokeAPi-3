#!/bin/bash
# Deployment script for the Enhanced Pokemon Collector with 2-EC2 Architecture
# This script automates the deployment of both game and backend instances

set -e  # Exit on any error

echo "POKEMON COLLECTOR - ENHANCED DEPLOYMENT SCRIPT"
echo "=================================================="

# Configuration
TERRAFORM_DIR="./terraform"
BACKEND_DIR="./backend"
GAME_DIR="./game"
KEY_FILE="${KEY_FILE:-~/.ssh/pokeapi-key.pem}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check if key file exists
    if [[ ! -f "$KEY_FILE" ]]; then
        print_warning "SSH key file not found at $KEY_FILE"
        print_status "Please ensure your SSH key file is available or set KEY_FILE environment variable"
    fi
    
    print_success "Prerequisites check complete!"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying AWS infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    terraform init
    
    # Plan the deployment
    print_status "Creating Terraform plan..."
    terraform plan -out=tfplan
    
    # Apply the plan
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Save outputs to a file for later use
    terraform output -json > ../terraform_outputs.json
    
    cd ..
    print_success "Infrastructure deployment complete!"
}

# Extract IP addresses from Terraform outputs
get_instance_ips() {
    if [[ ! -f "terraform_outputs.json" ]]; then
        print_error "Terraform outputs file not found. Please run deployment first."
        exit 1
    fi
    
    GAME_IP=$(cat terraform_outputs.json | jq -r '.pokeapi_game_public_ip.value')
    BACKEND_IP=$(cat terraform_outputs.json | jq -r '.backend_system_public_ip.value')
    BACKEND_PRIVATE_IP=$(cat terraform_outputs.json | jq -r '.backend_system_private_ip.value')
    
    print_status "Instance IPs:"
    echo "  Game Instance (Public):    $GAME_IP"
    echo "  Backend Instance (Public): $BACKEND_IP"
    echo "  Backend Instance (Private): $BACKEND_PRIVATE_IP"
}

# Wait for instances to be ready
wait_for_instances() {
    print_status "Waiting for instances to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_status "Attempt $attempt/$max_attempts - Testing SSH connectivity..."
        
        if ssh -i "$KEY_FILE" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@"$BACKEND_IP" "echo 'Backend ready'" &> /dev/null && \
           ssh -i "$KEY_FILE" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@"$GAME_IP" "echo 'Game ready'" &> /dev/null; then
            print_success "Both instances are ready!"
            return 0
        fi
        
        sleep 30
        ((attempt++))
    done
    
    print_error "Instances did not become ready within expected time"
    exit 1
}

# Deploy backend services
deploy_backend() {
    print_status "Deploying backend services..."
    
    # Copy backend files to the backend instance
    print_status "Copying backend files..."
    scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -r "$BACKEND_DIR"/* ec2-user@"$BACKEND_IP":/opt/pokeapi-backend/
    
    # Start backend services
    print_status "Starting backend services..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@"$BACKEND_IP" << 'EOF'
        cd /opt/pokeapi-backend
        
        # Build and start the backend services
        docker-compose down 2>/dev/null || true
        docker-compose build
        docker-compose up -d
        
        # Wait for services to be ready
        echo "Waiting for backend services to start..."
        sleep 30
        
        # Check if services are running
        docker-compose ps
        
        echo "Backend deployment complete!"
EOF
    
    print_success "Backend services deployed!"
}

# Deploy game files
deploy_game() {
    print_status "Deploying game files..."
    
    # Create backend URL configuration for the game
    cat > "$GAME_DIR/backend_config.py" << EOF
# Auto-generated backend configuration
BACKEND_URL = "http://$BACKEND_PRIVATE_IP:5000"
BACKEND_PUBLIC_URL = "http://$BACKEND_IP:5000"
EOF
    
    # Copy game files to the game instance
    print_status "Copying game files..."
    scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -r "$GAME_DIR"/* ec2-user@"$GAME_IP":/opt/pokeapi-game/
    
    # Setup game environment
    print_status "Setting up game environment..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@"$GAME_IP" << 'EOF'
        cd /opt/pokeapi-game
        
        # Install Python dependencies
        pip3 install -r requirements.txt 2>/dev/null || echo "Requirements file not found, skipping..."
        
        # Make sure the game is executable
        chmod +x main.py 2>/dev/null || true
        
        echo "Game deployment complete!"
EOF
    
    print_success "Game files deployed!"
}

# Test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Test backend health
    print_status "Testing backend health endpoint..."
    if curl -f "http://$BACKEND_IP:5000/health" &> /dev/null; then
        print_success "Backend health check passed!"
    else
        print_warning "Backend health check failed"
    fi
    
    # Test game connectivity
    print_status "Testing game connectivity..."
    if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@"$GAME_IP" 'cd /opt/pokeapi-game && python3 -c "print(\"Game test passed\")"'; then
        print_success "Game connectivity test passed!"
    else
        print_warning "Game connectivity test failed"
    fi
}

# Show deployment summary
show_deployment_summary() {
    print_success "🎉 DEPLOYMENT COMPLETE! 🎉"
    echo ""
    echo "  DEPLOYMENT SUMMARY:"
    echo "======================"
    echo ""
    echo "   Game Instance:"
    echo "   Public IP:  $GAME_IP"
    echo "   SSH:        ssh -i $KEY_FILE ec2-user@$GAME_IP"
    echo "   Game Path:  /opt/pokeapi-game/"
    echo ""
    echo "   Backend Instance:"
    echo "   Public IP:   $BACKEND_IP"
    echo "   Private IP:  $BACKEND_PRIVATE_IP"
    echo "   SSH:         ssh -i $KEY_FILE ec2-user@$BACKEND_IP"
    echo "   API URL:     http://$BACKEND_IP:5000"
    echo "   Backend Path: /opt/pokeapi-backend/"
    echo ""
    echo "   Quick Commands:"
    echo "   Start Game:     ssh -i $KEY_FILE ec2-user@$GAME_IP 'cd /opt/pokeapi-game && python3 main.py'"
    echo "   Check Backend:  curl http://$BACKEND_IP:5000/health"
    echo "   Backend Logs:   ssh -i $KEY_FILE ec2-user@$BACKEND_IP 'cd /opt/pokeapi-backend && docker-compose logs -f'"
    echo ""
    echo "  Next Steps:"
    echo "   1. Test the game by SSH'ing into the game instance"
    echo "   2. Run 'python3 main.py' to start the Pokemon Collector"
    echo "   3. Check backend logs if you encounter any issues"
    echo "   4. Monitor costs in your AWS console"
    echo ""
}

# Main deployment function
main() {
    echo "Starting deployment process..."
    echo ""
    
    check_prerequisites
    echo ""
    
    deploy_infrastructure
    echo ""
    
    get_instance_ips
    echo ""
    
    wait_for_instances
    echo ""
    
    deploy_backend
    echo ""
    
    deploy_game
    echo ""
    
    test_deployment
    echo ""
    
    show_deployment_summary
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "destroy")
        print_warning "Destroying infrastructure..."
        cd "$TERRAFORM_DIR"
        terraform destroy -auto-approve
        cd ..
        print_success "Infrastructure destroyed!"
        ;;
    "status")
        if [[ -f "terraform_outputs.json" ]]; then
            get_instance_ips
            test_deployment
        else
            print_error "No deployment found. Run './deploy.sh deploy' first."
        fi
        ;;
    "help")
        echo "Usage: $0 [deploy|destroy|status|help]"
        echo ""
        echo "Commands:"
        echo "  deploy   - Deploy the complete Pokemon Collector system (default)"
        echo "  destroy  - Destroy all AWS infrastructure"
        echo "  status   - Check the status of current deployment"
        echo "  help     - Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  KEY_FILE - Path to SSH private key file (default: ~/.ssh/pokeapi-key.pem)"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information."
        exit 1
        ;;
esac
