resource "tls_private_key" "auth_token_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256" # This corresponds to prime256v1 (secp256r1)
}

resource "aws_secretsmanager_secret" "auth_token_public_key" {
  name = "${var.name}/auth-public-key"
}

resource "aws_secretsmanager_secret_version" "auth_token_public_value" {
  secret_id     = aws_secretsmanager_secret.auth_token_public_key.id
  secret_string = tls_private_key.auth_token_key.public_key_pem
}

resource "aws_secretsmanager_secret" "auth_token_private_key" {
  name = "${var.name}/auth-private-key"
}

resource "aws_secretsmanager_secret_version" "auth_token_private_value" {
  secret_id     = aws_secretsmanager_secret.auth_token_private_key.id
  secret_string = tls_private_key.auth_token_key.private_key_pem
}

resource "tls_private_key" "jumphost_key" {
  count     = var.external_access.use_proxy ? 1 : 0
  algorithm = "ED25519"
}

resource "aws_secretsmanager_secret" "jumphosts_public_key" {
  count = var.external_access.use_proxy ? 1 : 0
  name  = "${var.name}/jumphost-public"
}

resource "aws_secretsmanager_secret_version" "jumphost_public_value" {
  count         = var.external_access.use_proxy ? 1 : 0
  secret_id     = aws_secretsmanager_secret.jumphosts_public_key[0].id
  secret_string = tls_private_key.jumphost_key[0].public_key_openssh
}

resource "aws_secretsmanager_secret" "jumphosts_private_key" {
  count = var.external_access.use_proxy ? 1 : 0
  name  = "${var.name}/jumphost-private"
}

resource "aws_secretsmanager_secret_version" "jumphost_private_value" {
  count         = var.external_access.use_proxy ? 1 : 0
  secret_id     = aws_secretsmanager_secret.jumphosts_private_key[0].id
  secret_string = tls_private_key.jumphost_key[0].private_key_pem
}

resource "tls_private_key" "saml_sp_key" {
  count      = var.enable_saml ? 1 : 0
  algorithm  = "RSA"
  rsa_bits   = 2048
}

resource "aws_secretsmanager_secret" "saml_sp_public_key" {
  count = var.enable_saml ? 1 : 0
  name  = "${var.name}/saml-sp-public-key"
}

resource "aws_secretsmanager_secret_version" "saml_sp_public_value" {
  count         = var.enable_saml ? 1 : 0
  secret_id     = aws_secretsmanager_secret.saml_sp_public_key[0].id
  secret_string = tls_private_key.saml_sp_key[0].public_key_pem
}

resource "aws_secretsmanager_secret" "saml_sp_private_key" {
  count = var.enable_saml ? 1 : 0
  name  = "${var.name}/saml-sp-private-key"
}

resource "aws_secretsmanager_secret_version" "saml_sp_private_value" {
  count         = var.enable_saml ? 1 : 0
  secret_id     = aws_secretsmanager_secret.saml_sp_private_key[0].id
  secret_string = tls_private_key.saml_sp_key[0].private_key_pem
}