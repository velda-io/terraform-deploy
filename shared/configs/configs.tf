locals {
  envoy_config = templatefile("${path.module}/envoy.yaml", {
    domain        = var.domain,
    https_enabled = var.https_certs != null,
  })

  config_file = yamlencode(local.config)
}

output "configs" {
  value = {
    envoy-config = jsonencode(yamldecode(local.envoy_config))
    velda-config = local.config_file
    nginx        = <<EOF
server {
    listen 3000;
    server_name ${var.domain};

    root /opt/velda/web;
    index index.html;

    location / {
        try_files $uri /index.html;
    }
}
EOF
    systemd      = <<EOF
[Unit]
Description=Start Velda server
Requires=docker.service
After=docker.service

[Service]
ExecStart=/opt/velda/start.sh
Restart=always
RestartSec=5
Environment="PATH=/usr/bin:/bin:/snap/bin"
Environment="DOMAIN=${var.domain}"
Environment="HOME=/root"
StandardError=journal

[Install]
WantedBy=default.target
EOF

    nfs-exports = format("/zpool %s\n", join(" ", [for cidr in var.agent_cidrs :
      "${cidr}(async,wdelay,hide,crossmnt,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)"])
    )
  }
}
