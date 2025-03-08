#!/bin/bash
set -ex

function get_metadata() {
    curl -f -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$1"
}

function install() {
    echo "Installing velda binary"
    DOMAIN=$(get_metadata velda-domain)

    apt update && sudo apt install docker.io zfsutils-linux nfs-kernel-server nginx -y --no-install-recommends
    rm -f /usr/share/keyrings/cloud.google.gpg && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list

    apt update && apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y
    # TODO: Fix this.
    gke_auth_command=$(get_metadata gke-auth || echo "NA")
    if [[ ${gke_auth_command} != "NA" ]]; then
        HOME=/root ${gke_auth_command}
    fi

    zpool create zpool /dev/disk/by-id/google-zfs || zpool status zpool
    zfs create zpool/images || zfs wait zpool/images

    # Download velda binary
    gsutil cp gs://novahub-release/server-v1.tar.gz /tmp/velda-release.tar.gz
    rm -rf /opt/velda
    mkdir -p /opt/velda
    tar -C /opt/ -xf /tmp/velda-release.tar.gz

    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install
    rm -f add-google-cloud-ops-agent-repo.sh
}

function setup() {
    # Setup nginx
    chown -R www-data:www-data /opt/velda/web
    ln -sf /etc/nginx/sites-available/velda /etc/nginx/sites-enabled/velda
    rm -f /etc/nginx/sites-enabled/default
    systemctl restart nginx

    # Setup envoy
    docker rm -f envoy || true
    docker run --log-driver=gcplogs -d --name envoy --add-host=host.docker.internal:host-gateway -p 80:80 -p 443:443 -v /run/velda/envoy/:/etc/envoy/ envoyproxy/envoy:v1.26.0

    # Setup systemd service
    systemctl daemon-reload

    systemctl enable velda
    systemctl restart velda
    systemctl restart google-cloud-ops-agent
    touch /opt/velda/installed
}

function save_config() {
    curl -f -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$1" -o $2
}

function fetch_secret() {
    gcloud secrets versions access latest --secret $(get_metadata velda-instance)-$1 > $2
}

function save_configs() {
    mkdir -p /run/velda/envoy
    fetch_secret "certs-csr" /run/velda/envoy/cert.pem || true
    fetch_secret "certs-key" /run/velda/envoy/key.pem || true
    fetch_secret "jumphost-public" /run/velda/jumphost.pub || true
    fetch_secret "jumphost-private" /run/velda/jumphost || true
    save_config envoy-config /run/velda/envoy/envoy.yaml
    save_config velda-config /run/velda/config.yaml
    save_config auth-private-key /run/velda/access-token-private-key.pem
    chmod 0600 /run/velda/access-token-private-key.pem
    save_config auth-public-key /run/velda/access-token-public-key.pem
    save_config nginx /etc/nginx/sites-available/velda
    save_config systemd /etc/systemd/system/velda.service
    save_config nfs-exports /etc/exports
    save_config ops-agent-config /etc/google-cloud-ops-agent/config.yaml
}

if [[ ! -e /opt/velda/installed ]]; then
    install
fi
save_configs
if [[ ! -e /opt/velda/installed ]]; then
    setup
fi

exportfs -a
echo "Starting velda service"
docker start envoy
systemctl start velda
