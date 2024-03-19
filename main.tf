provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

// We need a keypair to obtain the local administrator credentials to an AWS Windows based EC2 instance. So we generate it locally here
resource "tls_private_key" "rsa-4096-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Create an aws keypair using the keypair we just generated
resource "aws_key_pair" "rdp-key" {
  key_name = "RDeeP"
  public_key = tls_private_key.rsa-4096-key.public_key_openssh
}

// Create an AWS security group to allow RDP traffic in and out to from IP's on the allowlist
resource "aws_security_group" "rdp_ingress" {
  name   = "${var.name}-rdp-ingress"
  vpc_id = data.aws_vpc.default.id

  # RDP
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowlist_ip]
  }

    ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "udp"
    cidr_blocks = [var.allowlist_ip]
  }
  
}

// Create an AWS security group to allow all traffic originating from the default vpc
resource "aws_security_group" "allow_all_internal" {
  name   = "${var.name}-allow-all-internal"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Deploy a Windows EC2 instance using the previously created, aws_security_group's, aws_key_pair and use a userdata script to create a windows domain controller
resource "aws_instance" "domain_controller" {
  ami                    = var.ami
  instance_type          = var.domain_controller_instance_type
  vpc_security_group_ids = [aws_security_group.rdp_ingress.id, aws_security_group.allow_all_internal.id]
  key_name               = aws_key_pair.rdp-key.key_name

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  user_data = <<EOF
                <powershell>
                  $password = ConvertTo-SecureString ${var.admin_password} -AsPlainText -Force
                  Add-WindowsFeature -name ad-domain-services -IncludeManagementTools
                  Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.active_directory_domain} -DomainNetbiosName ${var.active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true
                </powershell>
              EOF
  
  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}