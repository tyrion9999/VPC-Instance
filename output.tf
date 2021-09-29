output publicip {
  value       = aws_instance.web.*.public_ip
  sensitive   = false
  description = "description"

}
