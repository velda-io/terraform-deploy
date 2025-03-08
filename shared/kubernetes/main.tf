
resource "kubernetes_manifest" "crd" {
  manifest = yamldecode(file("${path.module}/crd.yaml"))
}

resource "kubernetes_manifest" "node_setup" {
  manifest = yamldecode(file("${path.module}/node-setup.yaml"))
}