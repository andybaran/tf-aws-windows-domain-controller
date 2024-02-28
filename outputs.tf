output "Server_IP_Addresses" {
  value = <<CONFIGURATION
Server public IPs: ${join(", ", aws_instance.domain_controller[*].public_ip)}
CONFIGURATION
}