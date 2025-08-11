# =============================================================================
# PokeAPI Backend Deployment Script for Windows PowerShell
# =============================================================================
# Easy deployment script for different environments

param(
    [string]$Environment = "dev",
    [string]$Action = "up",
    [switch]$Detach,
    [switch]$Build,
    [switch]$Help
)

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to show help
function Show-Help {
    Write-Host @"
PokeAPI Backend Deployment Script for Windows

Usage: .\deploy.ps1 [OPTIONS] [ACTION]

ACTIONS:
    up              Start services (default)
    down            Stop services
    restart         Restart services
    logs            Show logs
    status          Show service status
    build           Build images
    clean           Clean up containers and volumes

OPTIONS:
    -Environment ENV    Environment: dev, prod (default: dev)
    -Detach            Run in detached mode (background)
    -Build             Build images before starting
    -Help              Show this help message

EXAMPLES:
    # Start development environment
    .\deploy.ps1

    # Start production environment in background
    .\deploy.ps1 -Environment prod -Detach -Action up

    # Build and start development with logs
    .\deploy.ps1 -Build -Environment dev -Action up

    # Stop production environment
    .\deploy.ps1 -Environment prod -Action down

    # View logs for development
    .\deploy.ps1 -Environment dev -Action logs

    # Clean up everything
    .\deploy.ps1 -Action clean

ENVIRONMENT FILES:
    Development: .env.dev
    Production:  .env.prod (copy from .env.prod.template)

"@
}

# Show help if requested
if ($Help) {
    Show-Help
    exit 0
}

# Validate environment
if ($Environment -notin @("dev", "prod")) {
    Write-Error "Invalid environment: $Environment. Use 'dev' or 'prod'"
    exit 1
}

# Validate action
$ValidActions = @("up", "down", "restart", "logs", "status", "build", "clean")
if ($Action -notin $ValidActions) {
    Write-Error "Invalid action: $Action. Valid actions: $($ValidActions -join ', ')"
    exit 1
}

# Set compose files and environment file based on environment
if ($Environment -eq "dev") {
    $ComposeFiles = "-f docker-compose.yml -f docker-compose.dev.yml"
    $EnvFile = ".env.dev"
}
elseif ($Environment -eq "prod") {
    $ComposeFiles = "-f docker-compose.yml -f docker-compose.prod.yml"
    $EnvFile = ".env.prod"
}

# Check if environment file exists
if (!(Test-Path $EnvFile)) {
    if ($Environment -eq "prod" -and (Test-Path ".env.prod.template")) {
        Write-Warning "Production environment file not found. Copying template..."
        Copy-Item ".env.prod.template" ".env.prod"
        Write-Warning "Please edit .env.prod with secure passwords and keys before proceeding!"
        exit 1
    }
    else {
        Write-Error "Environment file not found: $EnvFile"
        exit 1
    }
}

# Build flags
$BuildFlag = if ($Build) { "--build" } else { "" }
$DetachFlag = if ($Detach) { "-d" } else { "" }

# Build docker-compose command
$DockerComposeCmd = "docker-compose --env-file $EnvFile $ComposeFiles"

Write-Status "Environment: $Environment"
Write-Status "Action: $Action"
Write-Status "Compose files: $ComposeFiles"
Write-Status "Environment file: $EnvFile"

# Execute the requested action
try {
    switch ($Action) {
        "up" {
            Write-Status "Starting services..."
            $cmd = "$DockerComposeCmd up $BuildFlag $DetachFlag"
            Invoke-Expression $cmd
            if ($Detach) {
                Write-Success "Services started in background"
                Write-Status "View logs with: .\deploy.ps1 -Environment $Environment -Action logs"
                Write-Status "Check status with: .\deploy.ps1 -Environment $Environment -Action status"
            }
        }
        "down" {
            Write-Status "Stopping services..."
            Invoke-Expression "$DockerComposeCmd down"
            Write-Success "Services stopped"
        }
        "restart" {
            Write-Status "Restarting services..."
            Invoke-Expression "$DockerComposeCmd restart"
            Write-Success "Services restarted"
        }
        "logs" {
            Write-Status "Showing logs..."
            Invoke-Expression "$DockerComposeCmd logs -f"
        }
        "status" {
            Write-Status "Service status:"
            Invoke-Expression "$DockerComposeCmd ps"
            Write-Host ""
            Write-Status "Health status:"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Where-Object { $_ -match "pokeapi" }
        }
        "build" {
            Write-Status "Building images..."
            Invoke-Expression "$DockerComposeCmd build --no-cache"
            Write-Success "Images built successfully"
        }
        "clean" {
            Write-Warning "This will remove all containers, volumes, and networks!"
            $confirmation = Read-Host "Are you sure? (y/N)"
            if ($confirmation -eq "y" -or $confirmation -eq "Y") {
                Write-Status "Cleaning up..."
                Invoke-Expression "$DockerComposeCmd down -v --remove-orphans"
                docker system prune -f
                Write-Success "Cleanup completed"
            }
            else {
                Write-Status "Cleanup cancelled"
            }
        }
    }

    Write-Success "Operation completed successfully!"

    # Show useful endpoints for up action
    if ($Action -eq "up" -and $Detach) {
        Write-Host ""
        Write-Status "API Endpoints:"
        Write-Host "  Health Check: http://localhost:5000/health"
        Write-Host "  Pokemon API:  http://localhost:5000/pokemon"
        Write-Host "  Swagger UI:   http://localhost:5000/docs (if enabled)"
        Write-Host ""
        Write-Status "MongoDB:"
        if ($Environment -eq "dev") {
            Write-Host "  Connection: mongodb://localhost:27017/pokeapi_game_dev"
        }
        else {
            Write-Host "  Connection: mongodb://admin:password@localhost:27017/pokeapi_game"
        }
    }

}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
