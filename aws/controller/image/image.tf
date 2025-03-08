resource "null_resource" "image" {
  triggers = {
    instance_id   = var.controller_instance.id
    instance_name = var.controller_instance.name
    zone          = var.controller_instance.zone
    image_name    = var.image_name
    docker_name   = var.docker_name
    project       = var.controller_instance.project
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh your-username@${var.controller_instance.name} \
        --zone=${var.controller_instance.zone} \
        --project=${self.triggers.project} \
        --tunnel-through-iap \
        --command "while [ ! -f /opt/velda/installed ]; do echo Waiting for velda to be installed; sleep 1; done; sudo /opt/velda/bin/init_agent_image.sh ${var.docker_name} ${var.image_name};"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      gcloud compute ssh your-username@${self.triggers.instance_name} \
        --zone=${self.triggers.zone} \
        --project=${self.triggers.project} \
        --tunnel-through-iap \
        --command "zfs destroy -r zpool/images/${self.triggers.image_name} || true"
    EOT
  }
}

variable "docker_name" {
  description = "Name of the docker image to provision from. It must be publicly available."
  type        = string
}

variable "image_name" {
  description = "Velda image name"
  type        = string
}

variable "controller_instance" {
  description = "Controller instance"
  type = object({
    project = string
    id      = string
    name    = string
    zone    = string
  })
}