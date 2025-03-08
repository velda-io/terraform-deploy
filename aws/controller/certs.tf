resource "aws_secretsmanager_secret" "certs_csr" {
  count = var.https_certs != null ? 1 : 0
  name  = "${var.name}/certs-csr"
}

resource "aws_secretsmanager_secret_version" "cert_csr_value" {
  count         = var.https_certs != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.certs_csr[0].id
  secret_string = var.https_certs.cert
}

resource "aws_secretsmanager_secret" "certs_key" {
  count = var.https_certs != null ? 1 : 0
  name  = "${var.name}/certs-key"
}

resource "aws_secretsmanager_secret_version" "cert_key_value" {
  count         = var.https_certs != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.certs_key[0].id
  secret_string = var.https_certs.key
}