provider "aws" {
    region = var.aws_region # Use the region specified in variables.tf
}

# VPC for better network control
resource "aws_vpc" "pokeapi_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    
    tags = {
        Name = "${var.project_name}-VPC"
        Environment = var.environment
    }
}

# Subnet for instance PokeAPI_Game
resource "aws_subnet" "pokeapi_subnet" {
    vpc_id                  = aws_vpc.pokeapi_vpc.id
    cidr_block              = var.subnet_cidr
    availability_zone       = var.availability_zone
    map_public_ip_on_launch = true
    
    tags = {
        Name = "${var.project_name}-Subnet"
        Environment = var.environment
    }
}

# Internet gateway for VPC 
resource "aws_internet_gateway" "pokeapi_igw" {
    vpc_id = aws_vpc.pokeapi_vpc.id
    
    tags = {
        Name = "PokeAPI_IGW"
    }
}

# Route table for the VPC
resource "aws_route_table" "pokeapi_rt" {
    vpc_id = aws_vpc.pokeapi_vpc.id
    
    route {
        cidr_block = "0.0.0.0/0" # Allow all outbound traffic
        gateway_id = aws_internet_gateway.pokeapi_igw.id
    }
    
    tags = {
        Name = "PokeAPI_RouteTable"
    }
}

# Route table association for the subnet    
resource "aws_route_table_association" "pokeapi_rta" {
    subnet_id      = aws_subnet.pokeapi_subnet.id
    route_table_id = aws_route_table.pokeapi_rt.id
}
 

# Key pair for SSH access
resource "aws_key_pair" "deployer" {
    key_name   = var.key_name # Use the key name specified in variables.tf
    public_key = file(var.public_key_path)
}

# Security group for allowing HTTP, SSH, MongoDB and Flask API traffic
resource "aws_security_group" "allow_http_ssh" {
    name        = "${var.project_name}-sg"
    description = "Allow HTTP, SSH, MongoDB and Flask API traffic"
    vpc_id      = aws_vpc.pokeapi_vpc.id
 
    ingress {
        from_port   = 22  
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = var.allowed_ssh_cidrs # SSH access
    }

    ingress {
        from_port   = var.flask_api_port
        to_port     = var.flask_api_port
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr] # Flask API - only from VPC
    }

    ingress {
        from_port   = var.mongodb_port
        to_port     = var.mongodb_port
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr] # MongoDB - only from VPC
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # HTTP for game frontend - open to all IPs
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
    }

    tags = {
        Name = "${var.project_name}-SecurityGroup"
        Environment = var.environment
    }
}

# Instance for PokeAPI Game
resource "aws_instance" "Pokeapi_Game" {
    ami                    = var.game_ami_id
    instance_type          = var.instance_type
    key_name               = aws_key_pair.deployer.key_name
    subnet_id              = aws_subnet.pokeapi_subnet.id
    vpc_security_group_ids = [aws_security_group.allow_http_ssh.id]

    # Install Python and dependencies for the game (Amazon Linux)
    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y python3 python3-pip git nginx
                
                # Install Python dependencies for the game
                pip3 install flask requests
                
                # Create app directory
                mkdir -p /opt/pokeapi-game
                chown ec2-user:ec2-user /opt/pokeapi-game
                
                # Set up nginx for serving the game frontend
                cat > /etc/nginx/conf.d/pokeapi-game.conf << 'NGINXEOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINXEOF
                
                # Remove default nginx config
                rm -f /etc/nginx/nginx.conf.default
                
                # Start and enable nginx
                systemctl start nginx
                systemctl enable nginx
                EOF

    tags = {
        Name = "${var.project_name}-Game-Instance"
        Purpose = "Game Frontend"
        Environment = var.environment
    }
}

# Instance for Backend System
resource "aws_instance" "Backend_System" {
    ami                    = var.backend_ami_id
    instance_type          = var.backend_instance_type
    key_name               = aws_key_pair.deployer.key_name
    subnet_id              = aws_subnet.pokeapi_subnet.id
    vpc_security_group_ids = [aws_security_group.allow_http_ssh.id]

    # Install Docker and Docker Compose for backend services (Amazon Linux)
    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y docker git
                
                # Install Docker Compose
                curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose
                
                # Add ec2-user to docker group
                usermod -aG docker ec2-user
                
                # Create backend directory
                mkdir -p /opt/pokeapi-backend
                chown ec2-user:ec2-user /opt/pokeapi-backend
                
                # Start and enable Docker
                systemctl start docker
                systemctl enable docker
                EOF

    tags = {
        Name = "${var.project_name}-Backend-System"
        Purpose = "Docker + MongoDB + Flask API"
        Environment = var.environment
    }
}

# See outputs in outputs.tf for public IPs and SSH commands