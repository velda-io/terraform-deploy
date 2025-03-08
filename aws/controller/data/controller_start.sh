#!/bin/bash
set -ex

function install_aws() {
    apt update && apt install docker.io zfsutils-linux nfs-kernel-server nginx unzip -y --no-install-recommends
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
}

function install() {
    echo "Installing velda binary"

    zpool create zpool /dev/xvdf || zpool status zpool
    zfs create zpool/images || zfs wait zpool/images

    # Download velda binary
    aws s3 cp --quiet s3://velda-release/velda-v1.tar.gz /tmp/velda-release.tar.gz
    rm -rf /opt/velda
    mkdir -p /opt/velda
    tar -C /opt/ -xf /tmp/velda-release.tar.gz

    # Setup nginx
    chown -R www-data:www-data /opt/velda/web
    ln -sf /etc/nginx/sites-available/velda /etc/nginx/sites-enabled/velda
    rm -f /etc/nginx/sites-enabled/default
    systemctl restart nginx

    # Setup envoy
    docker rm -f envoy || true
    docker run -d --name envoy --add-host=host.docker.internal:host-gateway -p 80:80 -p 443:443 -v /run/velda/envoy/:/etc/envoy/ envoyproxy/envoy:v1.26.0

    systemctl daemon-reload

    systemctl enable velda
    touch /opt/velda/installed
}

function fetch_secret() {
    aws secretsmanager get-secret-value --secret-id $1 --query SecretString --output text > $2
}

function fetch_ssm_parameter() {
    aws ssm get-parameter --name $1 --with-decryption --query Parameter.Value --output text > $2
}

function save_keys() {
    fetch_secret "${instance}/certs-csr" /run/velda/envoy/cert.pem || true
    fetch_secret "${instance}/certs-key" /run/velda/envoy/key.pem || true
    fetch_secret "${instance}/jumphost-public" /run/velda/jumphost.pub || true
    fetch_secret "${instance}/jumphost-private" /run/velda/jumphost || true
    fetch_secret "${instance}/auth-private-key" /run/velda/access-token-private-key.pem
    fetch_secret "${instance}/auth-public-key" /run/velda/access-token-public-key.pem
    fetch_ssm_parameter "/${instance}/envoy-config" /run/velda/envoy/envoy.yaml
    fetch_ssm_parameter "/${instance}/velda-config" /run/velda/config.yaml
    fetch_ssm_parameter "/${instance}/nfs-exports" /etc/exports
    fetch_ssm_parameter "/${instance}/systemd" /etc/systemd/system/velda.service
    fetch_ssm_parameter "/${instance}/nginx" /etc/nginx/sites-available/velda
    chmod 0600 /run/${instance}/access-token-private-key.pem

    systemctl restart velda
}

mkdir -p /run/velda/envoy

which aws > /dev/null || install_aws
save_keys

if [[ ! -e /opt/velda/installed ]]; then
    install
fi

exportfs -a
echo "Starting velda service"
docker start envoy
systemctl start nginx
systemctl start velda
