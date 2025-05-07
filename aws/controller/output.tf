output "controller_ip" {
  value = local.allow_public_access ? aws_eip.lb[0].public_ip : aws_instance.controller.public_ip
}

output "controller_ip_internal" {
  value = aws_instance.controller.private_ip
}

output "auth_public_key" {
  value = tls_private_key.auth_token_key.public_key_pem
}

output "controller" {
  value = {
    id   = aws_instance.controller.id
    name = aws_instance.controller.tags.Name
  }
}

output "agent_configs" {
  value = {
    name = var.name

    region             = var.region
    zone               = var.zone
    vpc_id             = var.vpc_id
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.agent_sg.id]
    controller_ip      = aws_instance.controller.private_ip
    instance_profile   = aws_iam_instance_profile.agent_profile.name
  }
}
