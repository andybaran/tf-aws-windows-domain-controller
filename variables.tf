variable "name" {
  description = "Prefix used to name various infrastructure components. Alphanumeric characters only."
  default     = "windows-rdp"
}

variable "region" {
  description = "The AWS region to deploy to."
  default = "us-east-2"
}

variable "ami" {
  description = "The AMI to use for the server and client machines. Output from the Packer build process."
}

variable "allowlist_ip" {
  description = "IP to allow access for the security groups (set 0.0.0.0/0 for world)"
}

variable "domain_controller_instance_type" {
  description = "The AWS instance type to use for servers."
  default     = "t2.micro"
}

variable "client_instance_type" {
  description = "The AWS instance type to use for clients."
  default     = "t2.micro"
}

variable "domain_controller_count" {
  description = "The number of servers to provision."
  default     = "1"
}

variable "client_count" {
  description = "The number of clients to provision."
  default     = "1"
}

variable "root_block_device_size" {
  description = "The volume size of the root block device."
  default     = 64
}

variable "ssh_pubkey" {
  description = "Public key to place on EC2 nodes for SSH logins"
  type = string
}

variable "active_directory_domain" {
  type = string 
  default = "mydomain.local"
}

variable "active_directory_netbios_name" {
  type = string
  default = "mydomain"
}

variable "admin_password" {
  type = string
}