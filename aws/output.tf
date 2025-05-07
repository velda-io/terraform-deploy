output "dns_instructions" {
  value = <<EOF
To set the DNS name, set the following DNS mapping:
${var.domain} -> ${module.controller.controller_ip} (A record)
*.i.${var.domain} -> ${var.domain} (CNAME record)
EOF
}
