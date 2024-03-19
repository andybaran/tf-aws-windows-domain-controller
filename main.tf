provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

// Allow RDP traffic in and out to from IP's on the allowlist
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
  
  /*
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [var.allowlist_ip]
  }

  
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
  */
}

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


// We need a keypair to obtain the local administrator credentials to an AWS Windows based EC2 instance
resource "tls_private_key" "rsa-4096-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Share our keypair with AWS
resource "aws_key_pair" "rdp-key" {
  key_name = "RDeeP"
  public_key = tls_private_key.rsa-4096-key.public_key_openssh
}

// THIS IS NOT secure but we will need the private key to retrieve the local admin password from AWS
output "private-key" {
  value = nonsensitive(tls_private_key.rsa-4096-key.private_key_pem)
}

resource "aws_instance" "domain_controller" {
  ami                    = var.ami
  instance_type          = var.domain_controller_instance_type
  vpc_security_group_ids = [aws_security_group.rdp_ingress.id, aws_security_group.allow_all_internal.id]
  key_name               = aws_key_pair.rdp-key.key_name
  count                  = var.domain_controller_count

   root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  user_data = <<EOF
                <powershell>
                  Import-Module ADDSDeployment
                  $password = ConvertTo-SecureString ${var.admin_password} -AsPlainText -Force
                  Add-WindowsFeature -name ad-domain-services -IncludeManagementTools
                  Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.active_directory_domain} -DomainNetbiosName ${var.active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true
                </powershell>
              EOF
  
 // iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}

/*
resource "aws_instance" "client" {
  ami                    = var.ami
  instance_type          = var.client_instance_type
  key_name               = aws_key_pair.mykey.key_name
  vpc_security_group_ids = [aws_security_group.nomad_ui_ingress.id, aws_security_group.ssh_ingress.id, aws_security_group.clients_ingress.id, aws_security_group.allow_all_internal.id]
  count                  = var.client_count
  depends_on             = [aws_instance.server]

   root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  user_data = templatefile("${path.module}/data-scripts/user-data-client.sh", {
    region                    = var.region
    cloud_env                 = "aws"
    retry_join                = var.retry_join

  })
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}
*/

/*
resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = var.name
  role        = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = var.name
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "auto_discover_cluster" {
  name   = "${var.name}-auto-discover-cluster"
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.auto_discover_cluster.json
}

data "aws_iam_policy_document" "auto_discover_cluster" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
    ]

    resources = ["*"]
  }
}
*/