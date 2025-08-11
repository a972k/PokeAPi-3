# PowerShell Ansible deployment script for Pokemon Collector
# This script replaces the user_data approach with proper configuration management

param(
    [Parameter(Position = 0)]
    [ValidateSet("deploy", "test", "help")]
    [string]$Command = "deploy"
)

# Configuration
$TerraformOutputs = "..\terraform_outputs.json"
$AnsibleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AnsibleInventory = Join-Path $AnsibleDir "inventory.yml"
$AnsiblePlaybook = Join-Path $AnsibleDir "playbook.yml"

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

function Write-AnsibleStatus {
    param([string]$Message)
    Write-Host "[ANSIBLE] $Message" -ForegroundColor $InfoColor
}

function Write-AnsibleSuccess {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $SuccessColor
}

function Write-AnsibleWarning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $WarningColor
}

function Write-AnsibleError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $ErrorColor
}

function Test-TerraformOutputs {
    if (!(Test-Path $TerraformOutputs)) {
        Write-AnsibleError "Terraform outputs file not found at $TerraformOutputs"
        Write-AnsibleError "Please run terraform apply first to create the infrastructure"
        exit 1
    }
    
    Write-AnsibleSuccess "Terraform outputs found"
}

function Get-InstanceIPs {
    $outputs = Get-Content $TerraformOutputs | ConvertFrom-Json
    
    $script:GameIP = $outputs.pokeapi_game_public_ip.value
    $script:BackendIP = $outputs.backend_system_public_ip.value
    $script:BackendPrivateIP = $outputs.backend_system_private_ip.value
    
    if (!$script:GameIP -or !$script:BackendIP -or !$script:BackendPrivateIP) {
        Write-AnsibleError "Could not extract instance IPs from Terraform outputs"
        exit 1
    }
    
    Write-AnsibleStatus "Instance IPs extracted:"
    Write-Host "  Game Instance: $($script:GameIP)"
    Write-Host "  Backend Instance: $($script:BackendIP) (Private: $($script:BackendPrivateIP))"
}

function New-DynamicInventory {
    Write-AnsibleStatus "Creating dynamic Ansible inventory..."
    
    $inventoryContent = @"
all:
  children:
    game_servers:
      hosts:
        game_instance:
          ansible_host: $($script:GameIP)
          ansible_user: ec2-user
          ansible_ssh_private_key_file: ~/.ssh/pokeapi-key.pem
          instance_type: t2.micro
          environment: production
    
    backend_servers:
      hosts:
        backend_instance:
          ansible_host: $($script:BackendIP)
          ansible_user: ec2-user
          ansible_ssh_private_key_file: ~/.ssh/pokeapi-key.pem
          instance_type: t2.small
          environment: production
  
  vars:
    ansible_python_interpreter: /usr/bin/python3
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    project_name: "pokeapi-pokemon-collector"
    
    # Application directories
    game_app_dir: "/opt/pokeapi-game"
    backend_app_dir: "/opt/pokeapi-backend"
    
    # Network configuration
    flask_api_port: 5000
    mongodb_port: 27017
    nginx_port: 80
    
    # Docker configuration
    docker_compose_version: "v2.20.0"
    
    # Python dependencies
    python_packages:
      - flask
      - requests
      - pymongo
      - python-dotenv
"@
    
    $inventoryContent | Out-File -FilePath $AnsibleInventory -Encoding UTF8
    Write-AnsibleSuccess "Dynamic inventory created"
}

function Wait-ForInstances {
    Write-AnsibleStatus "Waiting for instances to be accessible via SSH..."
    
    $maxAttempts = 30
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        Write-AnsibleStatus "Attempt $attempt/$maxAttempts"
        
        try {
            $gameTest = ssh -i ~/.ssh/pokeapi-key.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no "ec2-user@$($script:GameIP)" "echo 'Game ready'" 2>$null
            $backendTest = ssh -i ~/.ssh/pokeapi-key.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no "ec2-user@$($script:BackendIP)" "echo 'Backend ready'" 2>$null
            
            if ($gameTest -and $backendTest) {
                Write-AnsibleSuccess "Both instances are accessible!"
                return
            }
        }
        catch {
            # Continue trying
        }
        
        Start-Sleep 30
        $attempt++
    }
    
    Write-AnsibleError "Instances did not become accessible within expected time"
    exit 1
}

function Invoke-AnsiblePlaybook {
    Write-AnsibleStatus "Running Ansible playbook..."
    
    Push-Location $AnsibleDir
    
    try {
        # Check Ansible installation
        if (!(Get-Command ansible-playbook -ErrorAction SilentlyContinue)) {
            Write-AnsibleError "Ansible is not installed. Please install Ansible first."
            exit 1
        }
        
        # Run the playbook
        ansible-playbook -i $AnsibleInventory $AnsiblePlaybook -v
        
        if ($LASTEXITCODE -eq 0) {
            Write-AnsibleSuccess "Ansible playbook completed successfully!"
        }
        else {
            Write-AnsibleError "Ansible playbook execution failed!"
            exit 1
        }
    }
    finally {
        Pop-Location
    }
}

function Test-Deployment {
    Write-AnsibleStatus "Testing deployment..."
    
    # Test backend health
    Write-AnsibleStatus "Testing backend health endpoint..."
    try {
        $response = Invoke-WebRequest -Uri "http://$($script:BackendIP):5000/health" -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-AnsibleSuccess "Backend health check passed!"
        }
    }
    catch {
        Write-AnsibleWarning "Backend health check failed - services may still be starting"
    }
    
    # Test nginx on game instance
    Write-AnsibleStatus "Testing game instance nginx..."
    try {
        $response = Invoke-WebRequest -Uri "http://$($script:GameIP)" -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-AnsibleSuccess "Game instance nginx is responding!"
        }
    }
    catch {
        Write-AnsibleWarning "Game instance nginx test failed"
    }
}

function Show-Summary {
    Write-AnsibleSuccess "ANSIBLE DEPLOYMENT COMPLETE!"
    Write-Host ""
    Write-Host "DEPLOYMENT SUMMARY:" -ForegroundColor $InfoColor
    Write-Host "======================"
    Write-Host ""
    Write-Host "Game Instance (Frontend):"
    Write-Host "   Public IP:  $($script:GameIP)"
    Write-Host "   SSH:        ssh -i ~/.ssh/pokeapi-key.pem ec2-user@$($script:GameIP)"
    Write-Host "   URL:        http://$($script:GameIP)"
    Write-Host ""
    Write-Host "Backend Instance (API + Database):"
    Write-Host "   Public IP:  $($script:BackendIP)"
    Write-Host "   Private IP: $($script:BackendPrivateIP)"
    Write-Host "   SSH:        ssh -i ~/.ssh/pokeapi-key.pem ec2-user@$($script:BackendIP)"
    Write-Host "   API URL:    http://$($script:BackendIP):5000"
    Write-Host ""
    Write-Host "Management Commands:"
    Write-Host "   Re-run deployment:    .\ansible\deploy_ansible.ps1"
    Write-Host "   Check backend logs:   ssh -i ~/.ssh/pokeapi-key.pem ec2-user@$($script:BackendIP) 'cd /opt/pokeapi-backend && docker-compose logs -f'"
    Write-Host "   Restart services:     ansible-playbook -i inventory.yml playbook.yml --tags restart"
    Write-Host ""
}

function Invoke-MainDeployment {
    Write-Host "Pokemon Collector - Ansible Deployment" -ForegroundColor $InfoColor
    Write-Host "=========================================="
    Write-Host ""
    
    Test-TerraformOutputs
    Get-InstanceIPs
    New-DynamicInventory
    Wait-ForInstances
    Invoke-AnsiblePlaybook
    Test-Deployment
    Show-Summary
}

function Test-CurrentDeployment {
    Test-TerraformOutputs
    Get-InstanceIPs
    Test-Deployment
}

function Show-Help {
    Write-Host "Usage: .\deploy_ansible.ps1 [deploy|test|help]" -ForegroundColor $InfoColor
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  deploy  - Run complete Ansible deployment (default)"
    Write-Host "  test    - Test current deployment"
    Write-Host "  help    - Show this help message"
}

# Main script execution
switch ($Command) {
    "deploy" { Invoke-MainDeployment }
    "test" { Test-CurrentDeployment }
    "help" { Show-Help }
    default {
        Write-AnsibleError "Unknown command: $Command"
        Write-Host "Run '.\deploy_ansible.ps1 help' for usage information."
        exit 1
    }
}
