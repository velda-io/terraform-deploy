#!/bin/bash
set -e

function get_metadata() {
    curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$1"
}

function install () {
    DOMAIN=$(get_metadata VELDA_DOMAIN)

    apt update && sudo apt install docker.io zfsutils-linux nfs-kernel-server nginx -y --no-install-recommends
    rm -f /usr/share/keyrings/cloud.google.gpg && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list

    apt update && apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y
    # TODO: Customize this.
    #gcloud container clusters get-credentials demo-central --zone us-central1-a --project skyworkstation

    zpool create zpool /dev/disk/by-id/google-zfs || zpool status zpool
    zfs create zpool/images || zfs wait zpool/images

    # Download velda binary
    gsutil cp gs://novahub-release/server-v1.tar.gz /tmp/velda-release.tar.gz
    mkdir -p /opt/velda
    tar -C /opt/ -xf /tmp/velda-release.tar.gz

    # Setup nginx
    chown -R www-data:www-data /opt/velda/web
    cat << EOF | tee /etc/nginx/sites-available/velda
server {
    listen 3000;
    server_name ${DOMAIN};

    root /opt/velda/web;
    index index.html;

    location / {
        try_files \$uri /index.html;
    }
}
EOF
    ln -sf /etc/nginx/sites-available/velda /etc/nginx/sites-enabled/velda
    rm -f /etc/nginx/sites-enabled/default
    systemctl restart nginx

    # Setup envoy
    docker rm -f envoy || true
    docker run -d --name envoy --add-host=host.docker.internal:host-gateway -p 80:80 -p 443:443 -v /run/velda/envoy.yaml:/etc/envoy/envoy.yaml envoyproxy/envoy:v1.26.0
    # TODO: -v ${INSTALL_DIR}/https:/etc/certs for https

    # Setup systemd service
    cat > /etc/systemd/system/velda.service << EOF
[Unit]
Description=Start Velda server
Requires=docker.service
After=docker.service

[Service]
ExecStart=/opt/velda/start.sh
Restart=always
RestartSec=5
Environment="PATH=/usr/bin:/bin:/snap/bin"
Environment="DOMAIN=${DOMAIN}"
StandardError=journal

[Install]
WantedBy=default.target
EOF
    systemctl daemon-reload

    systemctl enable velda
    systemctl start velda
    touch /opt/velda/installed
}


function save_key() {
    curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$1" -o $2
}

function save_keys() {
	mkdir -p /run/velda
	save_key ENVOY_CONFIG /run/velda/envoy.yaml
	save_key VELDA_CONFIG /run/velda/config.yaml
	save_key AUTH_PRIVATE_KEY /run/velda/access-token-private-key.pem
	chmod 0600 /run/velda/access-token-private-key.pem
	save_key AUTH_PUBLIC_KEY /run/velda/access-token-public-key.pem
}

save_keys

if [[ ! -e /opt/velda/installed ]]; then
    install
else
    docker start envoy
    systemctl start velda
fi

