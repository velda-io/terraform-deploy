resource "kubernetes_config_map" "velda_config_configmap" {
  metadata {
    name = "velda-config"
  }

  data = {
    "velda.yaml" = yamlencode({
      broker = {
        address = "${var.controller_ip}:50051"
      }
    })
    "auth-key.pem" : var.auth_public_key
  }
}

resource "kubernetes_config_map" "apparmor_profile" {
  metadata {
    namespace = "kube-system"
    name      = "velda-apparmor-profile"
  }

  data = {
    "profile" : file("${path.module}/apparmor_profile")
  }
}