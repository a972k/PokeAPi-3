#!/bin/bash
# Ansible deployment script for Pokemon Collector

set -e

# Configuration
TERRAFORM_OUTPUTS="../terraform_outputs.json"
ANSIBLE_DIR="$(dirname "$0")"
ANSIBLE_INVENTORY="$ANSIBLE_DIR/inventory.yml"
ANSIBLE_PLAYBOOK="$ANSIBLE_DIR/playbook.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[ANSIBLE]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_terraform_outputs() {
    if [[ ! -f "$TERRAFORM_OUTPUTS" ]]; then
        print_error "Terraform outputs file not found"
        exit 1
    fi
}

extract_instance_ips() {
    GAME_IP=$(jq -r '.pokeapi_game_public_ip.value' "$TERRAFORM_OUTPUTS")
    BACKEND_IP=$(jq -r '.backend_system_public_ip.value' "$TERRAFORM_OUTPUTS")
    BACKEND_PRIVATE_IP=$(jq -r '.backend_system_private_ip.value' "$TERRAFORM_OUTPUTS")
}

create_dynamic_inventory() {
    print_status "Creating dynamic inventory..."
    cat > "$ANSIBLE_INVENTORY" <<EOF
all:
  children:
    game_servers:
      hosts:
        game_instance:
          ansible_host: $GAME_IP
          ansible_user: ec2-user
          ansible_ssh_private_key_file: ~/.ssh/pokeapi-key.pem
    backend_servers:
      hosts:
        backend_instance:
          ansible_host: $BACKEND_IP
          ansible_user: ec2-user
          ansible_ssh_private_key_file: ~/.ssh/pokeapi-key.pem
  vars:
    ansible_python_interpreter: /usr/bin/python3
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF
}

run_ansible_playbook() {
    print_status "Running Ansible playbook..."
    cd "$ANSIBLE_DIR"
    
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "Ansible not installed"
        exit 1
    fi
    
    if ansible-playbook -i "$ANSIBLE_INVENTORY" "$ANSIBLE_PLAYBOOK" -v; then
        print_success "Ansible completed successfully!"
    else
        print_error "Ansible failed!"
        exit 1
    fi
}

main() {
    check_terraform_outputs
    extract_instance_ips
    create_dynamic_inventory
    run_ansible_playbook
    print_success "Deployment complete!"
}

case "${1:-deploy}" in
    "deploy") main ;;
    "help") echo "Usage: $0 [deploy|help]" ;;
    *) print_error "Unknown command: $1"; exit 1 ;;
esac