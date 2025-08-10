# PowerShell Deployment script for the Enhanced Pokemon Collector with 2-EC2 Architecture
# This script automates the deployment of both game and backend instances

param(
    [Parameter(Position = 0)]
    [ValidateSet("deploy", "destroy", "status", "help")]
    [string]$Command = "deploy",
    
    [Parameter()]
    [string]$KeyFile = "$env:USERPROFILE\.ssh\pokeapi-key.pem"
)

# Configuration
$TerraformDir = ".\terraform"
$BackendDir = ".\backend"
$GameDir = ".\game"

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $InfoColor
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $SuccessColor
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $WarningColor
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $ErrorColor
}

function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check if Terraform is installed
    if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Error "Terraform is not installed. Please install Terraform first."
        exit 1
    }
    
    # Check if AWS CLI is configured
    try {
        aws sts get-caller-identity | Out-Null
    }
    catch {
        Write-Error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    }
    
    # Check if key file exists
    if (!(Test-Path $KeyFile)) {
        Write-Warning "SSH key file not found at $KeyFile"
        Write-Status "Please ensure your SSH key file is available or use -KeyFile parameter"
    }
    
    Write-Success "Prerequisites check complete!"
}

function Deploy-Infrastructure {
    Write-Status "Deploying AWS infrastructure with Terraform..."
    
    Push-Location $TerraformDir
    
    try {
        # Initialize Terraform
        terraform init
        
        # Plan the deployment
        Write-Status "Creating Terraform plan..."
        terraform plan -out=tfplan
        
        # Apply the plan
        Write-Status "Applying Terraform configuration..."
        terraform apply tfplan
        
        # Save outputs to a file for later use
        terraform output -json > ..\terraform_outputs.json
        
        Write-Success "Infrastructure deployment complete!"
    }
    finally {
        Pop-Location
    }
}

function Get-InstanceIPs {
    if (!(Test-Path "terraform_outputs.json")) {
        Write-Error "Terraform outputs file not found. Please run deployment first."
        exit 1
    }
    
    $outputs = Get-Content "terraform_outputs.json" | ConvertFrom-Json
    
    $script:GameIP = $outputs.pokeapi_game_public_ip.value
    $script:BackendIP = $outputs.backend_system_public_ip.value
    $script:BackendPrivateIP = $outputs.backend_system_private_ip.value
    
    Write-Status "Instance IPs:"
    Write-Host "  Game Instance (Public):    $script:GameIP"
    Write-Host "  Backend Instance (Public): $script:BackendIP"
    Write-Host "  Backend Instance (Private): $script:BackendPrivateIP"
}

function Wait-ForInstances {
    Write-Status "Waiting for instances to be ready..."
    
    $maxAttempts = 30
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        Write-Status "Attempt $attempt/$maxAttempts - Testing SSH connectivity..."
        
        # Test SSH connectivity (simplified for PowerShell)
        try {
            # Note: This is a simplified check. In production, you might want to use a more robust method
            $backendTest = ssh -i $KeyFile -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$script:BackendIP "echo 'Backend ready'" 2>$null
            $gameTest = ssh -i $KeyFile -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$script:GameIP "echo 'Game ready'" 2>$null
            
            if ($backendTest -and $gameTest) {
                Write-Success "Both instances are ready!"
                return
            }
        }
        catch {
            # Continue trying
        }
        
        Start-Sleep 30
        $attempt++
    }
    
    Write-Error "Instances did not become ready within expected time"
    exit 1
}

function Deploy-Backend {
    Write-Status "Deploying backend services with Ansible..."
    
    # Check if Ansible is available for modern configuration management
    # Ansible provides better error handling and idempotent operations
    if (!(Get-Command ansible-playbook -ErrorAction SilentlyContinue)) {
        Write-Warning "Ansible not found. Falling back to manual deployment..."
        Deploy-BackendManual
        return
    }
    
    # Use Ansible for deployment when available
    # This provides structured configuration management and better reliability
    Write-Status "Running Ansible playbook for backend configuration..."
    Push-Location ".\ansible"
    try {
        .\deploy_ansible.ps1 deploy
        Write-Success "Backend deployed with Ansible!"
    }
    catch {
        Write-Warning "Ansible deployment failed. Falling back to manual deployment..."
        Pop-Location
        Deploy-BackendManual
    }
    finally {
        Pop-Location
    }
}

function Deploy-BackendManual {
    Write-Status "Deploying backend services manually..."
    
    # Copy backend application files to the target instance
    # Includes Flask API, Docker configurations, and database setup scripts
    Write-Status "Copying backend files..."
    scp -i $KeyFile -o StrictHostKeyChecking=no -r "$BackendDir\*" "ec2-user@$($script:BackendIP):/opt/pokeapi-backend/"
    
    # Execute backend setup script on the remote instance
    # Installs Docker, Docker Compose, and starts the backend services
    Write-Status "Starting backend services..."
    $backendScript = @"
        cd /opt/pokeapi-backend
        
        # Install Docker and Docker Compose if not present from user_data
        # These may not be installed if Ansible is not available
        sudo yum install -y docker git
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-`$(uname -s)-`$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo usermod -aG docker ec2-user
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Build and start the backend services using Docker Compose
        # This includes MongoDB database and Flask API containers
        docker-compose down 2>/dev/null || true
        docker-compose build
        docker-compose up -d
        
        # Wait for services to be ready before proceeding
        # Backend services need time to initialize, especially MongoDB
        echo "Waiting for backend services to start..."
        sleep 30
        
        # Check if services are running properly
        # Provides feedback on deployment success
        docker-compose ps
        
        echo "Backend deployment complete!"
"@
    
    ssh -i $KeyFile -o StrictHostKeyChecking=no "ec2-user@$($script:BackendIP)" $backendScript
    
    Write-Success "Backend services deployed manually!"
}

function Deploy-Game {
    Write-Status "Deploying game files with Ansible..."
    
    # Check if Ansible is available and backend was deployed with Ansible
    # If both conditions are met, game deployment is handled by the same Ansible playbook
    if ((Get-Command ansible-playbook -ErrorAction SilentlyContinue) -and (Test-Path ".\ansible\inventory.yml")) {
        Write-Status "Game deployment handled by Ansible playbook"
        Write-Success "Game files deployed with Ansible!"
        return
    }
    
    # Fallback to manual deployment if Ansible is not available
    Deploy-GameManual
}

function Deploy-GameManual {
    Write-Status "Deploying game files manually..."
    
    # Create backend connection configuration for the game
    # This allows the game to connect to the Flask API on the backend instance
    # Uses private IP for internal VPC communication (more secure and faster)
    $backendConfig = @"
# Auto-generated backend configuration
BACKEND_URL = "http://$($script:BackendPrivateIP):5000"
BACKEND_PUBLIC_URL = "http://$($script:BackendIP):5000"
"@
    
    $backendConfig | Out-File -FilePath "$GameDir\backend_config.py" -Encoding UTF8
    
    # Copy game application files to the target instance
    # Includes Python game scripts, animations, storage management, etc.
    Write-Status "Copying game files..."
    scp -i $KeyFile -o StrictHostKeyChecking=no -r "$GameDir\*" "ec2-user@$($script:GameIP):/opt/pokeapi-game/"
    
    # Execute game setup script on the remote instance
    # Installs nginx, Python packages, and configures the web proxy
    Write-Status "Setting up game environment..."
    $gameScript = @"
        cd /opt/pokeapi-game
        
        # Install required packages if not present from user_data
        # Nginx serves as reverse proxy, git for potential updates
        sudo yum install -y nginx git
        sudo pip3 install flask requests
        
        # Configure nginx as reverse proxy for the game application
        # Routes web requests to the Python game running on port 8000
        sudo tee /etc/nginx/conf.d/pokeapi-game.conf > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
NGINXEOF
        
        # Start and enable nginx for automatic startup on boot
        sudo systemctl start nginx
        sudo systemctl enable nginx
        
        # Install Python dependencies from requirements file if present
        # Includes packages needed for Pokemon API integration and backend communication
        pip3 install -r requirements.txt 2>/dev/null || echo "Requirements file not found, skipping..."
        
        # Make the main game script executable
        chmod +x main.py 2>/dev/null || true
        
        echo "Game deployment complete!"
"@
    
    ssh -i $KeyFile -o StrictHostKeyChecking=no "ec2-user@$($script:GameIP)" $gameScript
    
    Write-Success "Game files deployed manually!"
}

function Test-Deployment {
    Write-Status "Testing deployment..."
    
    # Test backend health
    Write-Status "Testing backend health endpoint..."
    try {
        $response = Invoke-WebRequest -Uri "http://$($script:BackendIP):5000/health" -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Success "Backend health check passed!"
        }
    }
    catch {
        Write-Warning "Backend health check failed - services may still be starting"
    }
    
    # Test game instance accessibility
    Write-Status "Testing game instance..."
    try {
        $gameTest = ssh -i $KeyFile -o StrictHostKeyChecking=no "ec2-user@$($script:GameIP)" "echo 'Game instance accessible'"
        if ($gameTest) {
            Write-Success "Game instance test passed!"
        }
    }
    catch {
        Write-Warning "Game instance test failed"
    }
}

function Show-DeploymentSummary {
    Write-Success "DEPLOYMENT COMPLETE!"
    Write-Host ""
    Write-Host "DEPLOYMENT SUMMARY:" -ForegroundColor $InfoColor
    Write-Host "======================"
    Write-Host ""
    Write-Host "Game Instance (Frontend):"
    Write-Host "   Public IP:  $($script:GameIP)"
    Write-Host "   SSH:        ssh -i $KeyFile ec2-user@$($script:GameIP)"
    Write-Host "   Game Path:  /opt/pokeapi-game/"
    Write-Host ""
    Write-Host "Backend Instance (API + Database):"
    Write-Host "   Public IP:   $($script:BackendIP)"
    Write-Host "   Private IP:  $($script:BackendPrivateIP)"
    Write-Host "   SSH:         ssh -i $KeyFile ec2-user@$($script:BackendIP)"
    Write-Host "   API URL:     http://$($script:BackendIP):5000"
    Write-Host "   Backend Path: /opt/pokeapi-backend/"
    Write-Host ""
    Write-Host "Quick Commands:"
    Write-Host "   Start Game:     ssh -i $KeyFile ec2-user@$($script:GameIP) 'cd /opt/pokeapi-game && python3 main.py'"
    Write-Host "   Check Backend:  curl http://$($script:BackendIP):5000/health"
    Write-Host "   Backend Logs:   ssh -i $KeyFile ec2-user@$($script:BackendIP) 'cd /opt/pokeapi-backend && docker-compose logs -f'"
    Write-Host ""
    Write-Host "Next Steps:"
    Write-Host "   1. Test the game by SSH'ing into the game instance"
    Write-Host "   2. Run 'python3 main.py' to start the Pokemon Collector"
    Write-Host "   3. Check backend logs if you encounter any issues"
    Write-Host "   4. Monitor costs in your AWS console"
    Write-Host ""
}

function Invoke-MainDeployment {
    Write-Host "POKEMON COLLECTOR - ENHANCED DEPLOYMENT SCRIPT" -ForegroundColor $InfoColor
    Write-Host "=================================================="
    Write-Host ""
    
    Test-Prerequisites
    Write-Host ""
    
    Deploy-Infrastructure
    Write-Host ""
    
    Get-InstanceIPs
    Write-Host ""
    
    Wait-ForInstances
    Write-Host ""
    
    Deploy-Backend
    Write-Host ""
    
    Deploy-Game
    Write-Host ""
    
    Test-Deployment
    Write-Host ""
    
    Show-DeploymentSummary
}

function Invoke-Destroy {
    Write-Warning "Destroying infrastructure..."
    Push-Location $TerraformDir
    try {
        terraform destroy -auto-approve
        Write-Success "Infrastructure destroyed!"
    }
    finally {
        Pop-Location
    }
}

function Show-Status {
    if (Test-Path "terraform_outputs.json") {
        Get-InstanceIPs
        Test-Deployment
    }
    else {
        Write-Error "No deployment found. Run '.\deploy.ps1 deploy' first."
    }
}

function Show-Help {
    Write-Host "Usage: .\deploy.ps1 [deploy|destroy|status|help] [-KeyFile <path>]" -ForegroundColor $InfoColor
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  deploy   - Deploy the complete Pokemon Collector system (default)"
    Write-Host "  destroy  - Destroy all AWS infrastructure"
    Write-Host "  status   - Check the status of current deployment"
    Write-Host "  help     - Show this help message"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -KeyFile - Path to SSH private key file (default: `$env:USERPROFILE\.ssh\pokeapi-key.pem)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy.ps1 deploy"
    Write-Host "  .\deploy.ps1 destroy"
    Write-Host "  .\deploy.ps1 status -KeyFile C:\keys\my-key.pem"
}

# Main script execution
switch ($Command) {
    "deploy" { Invoke-MainDeployment }
    "destroy" { Invoke-Destroy }
    "status" { Show-Status }
    "help" { Show-Help }
    default {
        Write-Error "Unknown command: $Command"
        Write-Host "Run '.\deploy.ps1 help' for usage information."
        exit 1
    }
}