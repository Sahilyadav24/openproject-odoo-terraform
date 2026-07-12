#!/bin/bash
set -e
echo "=== Starting Setup ==="
apt-get update
apt-get upgrade -y
apt-get install -y curl wget git htop jq awscli
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu focal stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
usermod -aG docker ubuntu
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
# --- Fetch the real DB password from Secrets Manager ---
echo "=== Fetching DB password from Secrets Manager ==="
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "${db_secret_arn}" \
  --region "${aws_region}" \
  --query SecretString --output text)
if [ -z "$DB_PASSWORD" ] || [ "$DB_PASSWORD" == "null" ]; then
  echo "ERROR: Failed to fetch DB password from Secrets Manager" >&2
  exit 1
fi
mkdir -p /home/ubuntu/app
cat > /home/ubuntu/app/docker-compose.yml << DOCKER_EOF
version: '3.8'
services:
  openproject:
    image: openproject/openproject:14
    container_name: openproject
    restart: always
    ports:
      - "8000:80"
    environment:
      - OPENPROJECT_HOST__NAME=localhost
      - OPENPROJECT_HTTPS=false
      - DATABASE_URL=postgres://dbadmin:${"$"}{DB_PASSWORD}@${db_host}:5432/openproject_odoo
    volumes:
      - openproject-data:/var/openproject/assets
  odoo:
    image: odoo:17
    container_name: odoo
    restart: always
    ports:
      - "8080:8069"
    environment:
      - HOST=${db_host}
      - USER=dbadmin
      - PASSWORD=${"$"}{DB_PASSWORD}
    volumes:
      - odoo-data:/var/lib/odoo
    command: ["odoo", "-d", "openproject_odoo_odoo", "-i", "base", "--without-demo=all"]
volumes:
  openproject-data:
  odoo-data:
DOCKER_EOF
chown -R ubuntu:ubuntu /home/ubuntu/app
cd /home/ubuntu/app
docker-compose up -d
echo "=== Setup Complete ==="