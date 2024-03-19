// THIS IS NOT secure but we may need the private key to retrieve the local admin password from AWS
output "private-key" {
  value = nonsensitive(tls_private_key.rsa-4096-key.private_key_pem)
}

// This is the public DNS address of our instance
output "public-dns-address" {
  value = aws_instance.domain_controller.public_dns
}