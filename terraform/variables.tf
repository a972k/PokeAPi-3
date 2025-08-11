variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2" # Change as needed  
}

variable "availability_zone" {
  description = "The availability zone to deploy resources in"
  type        = string
  default     = "us-west-2a" # Should match the region
}

variable "key_name" {
  description = "The name of the SSH key pair to use for instances"
  type        = string
  default     = "vockab" # Adjust as needed
}       

variable "public_key_path" {
  description = "Path to the public SSH key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub" # Adjust path to your public key
}   

variable "instance_type" {
  description = "The type of instance to use for the PokeAPI game"
  type        = string
  default     = "t2.micro" # Free tier eligible
}   

variable "backend_instance_type" {
  description = "The type of instance to use for the backend system"
  type        = string
  default     = "t2.small" # For Docker + MongoDB
}

variable "game_ami_id" {
  description = "The AMI ID to use for the PokeAPI game instance"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2023 in us-west-2
}

variable "backend_ami_id" {
  description = "The AMI ID to use for the backend system"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2023 in us-west-2
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  default     = "pokeapi"
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH into instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Allow from anywhere - restrict for production
}

variable "flask_api_port" {
  description = "Port for the Flask API"
  type        = number
  default     = 5000
}

variable "mongodb_port" {
  description = "Port for MongoDB"
  type        = number
  default     = 27017
}

variable "game_frontend_port" {
  description = "Port for the game frontend"
  type        = number
  default     = 8000
}   
