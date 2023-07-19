output "public_ip" {
  description = "Public IP address of the web server."
  value = aws_instance.example.public_ip
}