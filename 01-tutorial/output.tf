output "alb_dns_name" {
  description = "DNS of the application load balancer"
  value = aws_lb.example.dns_name
}