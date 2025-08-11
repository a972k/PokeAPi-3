# Ansible Configuration Management for Pokemon Collector

This directory contains Ansible configuration files that replace the traditional user_data scripts with proper Infrastructure as Code (IaC) configuration management.

## 🎯 What Ansible Replaces

### Before: User Data Scripts

```bash
# Old approach in terraform/main.tf
user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker git
    # ... lots of inline bash
EOF
```

### After: Ansible Playbooks

```yaml
# New approach with ansible/playbook.yml
- name: Install Docker and dependencies
  yum:
    name: "{{ docker_packages }}"
    state: present
```

## 📁 File Structure

```text
ansible/
├── ansible.cfg           # Ansible configuration
├── inventory.yml         # Dynamic inventory template
├── playbook.yml         # Main deployment playbook
├── deploy_ansible.sh    # Linux deployment script
├── deploy_ansible.ps1   # Windows deployment script
└── templates/           # Jinja2 templates
    ├── backend_config.py.j2       # Backend configuration
    ├── docker-compose.yml.j2      # Docker Compose config
    └── nginx_game.conf.j2          # Nginx configuration
```

## 🚀 Quick Start

### Prerequisites

- Ansible installed (`pip install ansible` or `sudo apt install ansible`)
- Terraform infrastructure already deployed
- SSH access to EC2 instances

### 1. Deploy with Ansible (Recommended)

**Linux/Mac:**

```bash
# Deploy infrastructure with Terraform first
cd terraform
terraform apply

# Then configure with Ansible
cd ../ansible
./deploy_ansible.sh deploy
```

**Windows:**

```powershell
# Deploy infrastructure with Terraform first
cd terraform
terraform apply

# Then configure with Ansible
cd ..\ansible
.\deploy_ansible.ps1 deploy
```

### 2. Hybrid Deployment (Fallback)

The main deployment script automatically detects Ansible and falls back to manual configuration if Ansible is not available:

```powershell
# This will try Ansible first, then fallback to manual deployment
.\deploy.ps1 deploy
```

## 🔧 Ansible Playbook Structure

### Game Server Configuration

- ✅ System updates and package installation
- ✅ Python 3 and pip setup
- ✅ Nginx installation and configuration
- ✅ Game directory creation
- ✅ Backend connection configuration

### Backend Server Configuration

- ✅ Docker and Docker Compose installation
- ✅ User permissions and groups
- ✅ Application directory creation
- ✅ Docker Compose configuration
- ✅ Service startup and health checks

### Post-Deployment Validation

- ✅ Service availability checks
- ✅ Backend health endpoint testing
- ✅ Network connectivity validation

## 📊 Benefits of Ansible vs User Data

| Aspect | User Data | Ansible |
|--------|-----------|---------|
| **Idempotency** | ❌ Runs once only | ✅ Can be re-run safely |
| **Error Handling** | ❌ Basic bash error handling | ✅ Built-in error handling |
| **Templating** | ❌ Hard-coded values | ✅ Jinja2 templating |
| **Debugging** | ❌ Limited visibility | ✅ Verbose output and logging |
| **Reusability** | ❌ Terraform-specific | ✅ Works across environments |
| **Maintenance** | ❌ Inline bash is hard to maintain | ✅ Structured YAML |
| **Testing** | ❌ No testing framework | ✅ Ansible testing tools |
| **Rollback** | ❌ Manual process | ✅ State management |

## 🎛️ Configuration Management

### Dynamic Inventory

The inventory is dynamically generated from Terraform outputs:

```yaml
# Generated from terraform_outputs.json
game_servers:
  hosts:
    game_instance:
      ansible_host: "{{ terraform_game_ip }}"
      
backend_servers:
  hosts:
    backend_instance:
      ansible_host: "{{ terraform_backend_ip }}"
```

### Template Variables

Templates use variables from inventory and facts:

```yaml
# templates/backend_config.py.j2
BACKEND_URL = "http://{{ hostvars['backend_instance']['ansible_host'] }}:{{ flask_api_port }}"
MONGODB_URI = "mongodb://localhost:{{ mongodb_port }}/{{ mongo_db_name }}"
```

## 🔍 Debugging and Maintenance

### Check Ansible Status

```bash
# Test connectivity
ansible all -i inventory.yml -m ping

# Check service status
ansible backend_servers -i inventory.yml -m service -a "name=docker state=started"

# View system facts
ansible all -i inventory.yml -m setup
```

### Re-run Configuration

```bash
# Re-run entire playbook
ansible-playbook -i inventory.yml playbook.yml

# Run specific tags
ansible-playbook -i inventory.yml playbook.yml --tags "backend"

# Increase verbosity for debugging
ansible-playbook -i inventory.yml playbook.yml -vvv
```

### Manual Commands

```bash
# Check backend logs
ansible backend_servers -i inventory.yml -a "docker-compose -f /opt/pokeapi-backend/docker-compose.yml logs"

# Restart services
ansible backend_servers -i inventory.yml -a "systemctl restart docker"
ansible game_servers -i inventory.yml -a "systemctl restart nginx"
```

## 🔐 Security Considerations

### SSH Configuration

```ini
# ansible.cfg
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
pipelining = True
```

### Privilege Escalation

```yaml
# playbook.yml
become: true
become_method: sudo
become_user: root
```

### Sensitive Data

- SSH keys are referenced, not stored in code
- Environment variables for sensitive configuration
- Ansible Vault for encrypted secrets (if needed)

## 📈 Monitoring and Validation

### Health Checks

The playbook includes built-in health checks:

```yaml
- name: Verify backend health endpoint
  uri:
    url: "http://{{ backend_ip }}:5000/health"
    method: GET
    status_code: 200
```

### Service Validation

```yaml
- name: Wait for services to be ready
  wait_for:
    port: "{{ flask_api_port }}"
    host: "{{ ansible_host }}"
    timeout: 300
```

## 🚨 Troubleshooting

### Common Issues

1. **Ansible Not Found**

   ```bash
   # Install Ansible
   pip install ansible
   # or
   sudo apt install ansible
   ```

2. **SSH Key Issues**

   ```bash
   # Check key permissions
   chmod 400 ~/.ssh/pokeapi-key.pem
   
   # Test SSH connectivity
   ssh -i ~/.ssh/pokeapi-key.pem ec2-user@<instance-ip>
   ```

3. **Inventory Generation Failed**
   - Ensure `terraform_outputs.json` exists
   - Check Terraform outputs: `terraform output -json`

4. **Service Startup Issues**

   ```bash
   # Check service status
   ansible backend_servers -i inventory.yml -a "systemctl status docker"
   ansible game_servers -i inventory.yml -a "systemctl status nginx"
   ```

### Log Files

- Ansible execution log: `./ansible.log`
- Service logs: Available via Ansible ad-hoc commands
- Application logs: In respective directories on instances

## 🔄 Comparison: Before vs After

### Before (User Data)

```terraform
# In terraform/main.tf
user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y docker git
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
usermod -aG docker ec2-user
mkdir -p /opt/pokeapi-backend
chown ec2-user:ec2-user /opt/pokeapi-backend
systemctl start docker
systemctl enable docker
EOF
```

### After (Ansible)

```yaml
# In ansible/playbook.yml
- name: Install Docker packages
  yum:
    name: "{{ docker_packages }}"
    state: present

- name: Download Docker Compose binary
  get_url:
    url: "https://github.com/docker/compose/releases/download/{{ docker_compose_version }}/docker-compose-{{ ansible_system }}-{{ ansible_architecture }}"
    dest: /usr/local/bin/docker-compose
    mode: '0755'

- name: Add ec2-user to docker group
  user:
    name: ec2-user
    groups: docker
    append: yes

- name: Create backend application directory
  file:
    path: "{{ backend_app_dir }}"
    state: directory
    owner: ec2-user
    group: ec2-user

- name: Start and enable Docker service
  systemd:
    name: docker
    state: started
    enabled: yes
```

## 🎯 Migration Benefits

1. **Maintainability**: YAML is easier to read and maintain than inline bash
2. **Reusability**: Playbooks can be used across environments
3. **Error Handling**: Better error reporting and recovery
4. **Idempotency**: Safe to re-run without side effects
5. **Testing**: Can be tested with ansible-lint and molecule
6. **Documentation**: Self-documenting through task names
7. **Version Control**: Better diff and merge capabilities
8. **Scalability**: Easy to add more instances or services

---

**Migration Complete**: Your Pokemon Collector now uses modern configuration management with Ansible! 🎉
