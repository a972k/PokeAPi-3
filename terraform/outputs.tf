# Terraform Outputs - All output values for the PokeAPI infrastructure

output "pokeapi_game_public_ip" {
    description = "Public IP address of the PokeAPI Game instance"
    value       = aws_instance.Pokeapi_Game.public_ip
}

output "backend_system_public_ip" {
    description = "Public IP address of the Backend System instance"
    value       = aws_instance.Backend_System.public_ip
}

output "backend_system_private_ip" {
    description = "Private IP address of the Backend System (for internal API calls)"
    value       = aws_instance.Backend_System.private_ip
}

output "vpc_id" {
    description = "ID of the VPC"
    value       = aws_vpc.pokeapi_vpc.id
}

output "subnet_id" {
    description = "ID of the subnet"
    value       = aws_subnet.pokeapi_subnet.id
}

output "security_group_id" {
    description = "ID of the security group"
    value       = aws_security_group.allow_http_ssh.id
}

output "ssh_connection_commands" {
    description = "Commands to SSH into the instances"
    value = {
        pokeapi_game = "ssh -i ${var.public_key_path} ec2-user@${aws_instance.Pokeapi_Game.public_ip}"
        backend_system = "ssh -i ${var.public_key_path} ec2-user@${aws_instance.Backend_System.public_ip}"
    }
}

output "service_urls" {
    description = "URLs to access your services"
    value = {
        game_frontend = "http://${aws_instance.Pokeapi_Game.public_ip}"
        api_internal = "http://${aws_instance.Backend_System.private_ip}:${var.flask_api_port}"
        mongodb_internal = "mongodb://${aws_instance.Backend_System.private_ip}:${var.mongodb_port}"
    }
}

output "quick_start_guide" {
    description = "Quick start commands for deployment"
    value = <<-EOT
    
    QUICK START GUIDE:
    
    1. SSH into Game Instance:
       ${aws_instance.Pokeapi_Game.public_ip != "" ? "ssh -i ${var.public_key_path} ec2-user@${aws_instance.Pokeapi_Game.public_ip}" : "Instance not ready yet"}
    
    2. SSH into Backend Instance:
       ${aws_instance.Backend_System.public_ip != "" ? "ssh -i ${var.public_key_path} ec2-user@${aws_instance.Backend_System.public_ip}" : "Instance not ready yet"}
    
    3. Upload your code:
       scp -r -i ${var.public_key_path} ./game/* ec2-user@${aws_instance.Pokeapi_Game.public_ip}:/opt/pokeapi-game/
       scp -r -i ${var.public_key_path} ./backend/* ec2-user@${aws_instance.Backend_System.public_ip}:/opt/pokeapi-backend/
    
    4. Start backend services:
       ssh -i ${var.public_key_path} ec2-user@${aws_instance.Backend_System.public_ip}
       cd /opt/pokeapi-backend && docker-compose up -d
    
    5. Access your game:
       http://${aws_instance.Pokeapi_Game.public_ip}
    
    EOT
}

output "deployment_notes" {
    description = "Important deployment information"
    value = <<-EOT
    DEPLOYMENT NOTES:
    
    • Environment: ${var.environment}
    • Project: ${var.project_name}
    • Region: ${var.aws_region}
    • Game Instance: ${var.instance_type} (${aws_instance.Pokeapi_Game.public_ip})
    • Backend Instance: ${var.backend_instance_type} (${aws_instance.Backend_System.public_ip})
    
    INTERNAL CONNECTIONS:
    • API Endpoint: http://${aws_instance.Backend_System.private_ip}:${var.flask_api_port}
    • MongoDB: mongodb://${aws_instance.Backend_System.private_ip}:${var.mongodb_port}
    
    SECURITY:
    • SSH User: ec2-user (Amazon Linux)
    • Key File: ${var.public_key_path}
    • API/DB only accessible within VPC
    
    COST ESTIMATE:
    • Game Instance (${var.instance_type}): ~$${var.instance_type == "t2.micro" ? "0 (free tier)" : "8.50"}/month
    • Backend Instance (${var.backend_instance_type}): ~$17/month
    
    EOT
}
