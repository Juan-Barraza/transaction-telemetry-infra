#!/bin/bash
set -euxo pipefail

apt-get update -y
apt-get install -y ca-certificates curl gnupg git
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker ubuntu
systemctl enable --now docker

mkdir -p /opt/app
cat > /opt/app/deploy.sh <<'EOF'
#!/bin/bash
set -euo pipefail
IMAGE=$1
NAME=$2
shift 2
ENV_FILE=/opt/app/${NAME}.env

PREV=$(docker inspect -f '{{.Config.Image}}' "$NAME" 2>/dev/null || true)

docker pull "$IMAGE"
docker rm -f "$NAME" 2>/dev/null || true
docker run -d --name "$NAME" --restart unless-stopped --env-file "$ENV_FILE" "$@" "$IMAGE"

sleep 20
if [ "$(docker inspect -f '{{.State.Running}}' "$NAME")" != "true" ]; then
  echo "El contenedor no arrancó"
  if [ -n "$PREV" ]; then
    docker rm -f "$NAME" || true
    docker run -d --name "$NAME" --restart unless-stopped --env-file "$ENV_FILE" "$@" "$PREV"
    echo "Rollback a $PREV"
  fi
  exit 1
fi
EOF
chmod +x /opt/app/deploy.sh