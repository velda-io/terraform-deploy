
resource "kubernetes_persistent_volume" "nfs_pv" {
  metadata {
    name = "velda-data"
  }

  spec {
    capacity = {
      # Doesn't matter, will match PVC.
      storage = "10Gi",
    }
    storage_class_name = "manual"

    access_modes = ["ReadWriteMany"]

    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      nfs {
        server = var.controller_ip
        path   = "/zpool"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "nfs_pvc" {
  metadata {
    name = "velda-data"
  }

  spec {
    access_modes = ["ReadWriteMany"]

    storage_class_name = "manual"
    resources {
      requests = {
        storage = "10Gi"
      }
    }

    volume_name = kubernetes_persistent_volume.nfs_pv.metadata[0].name
  }
}
