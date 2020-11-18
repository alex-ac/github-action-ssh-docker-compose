#!/usb/bin/env bash
set -e

log() {
  echo ">> [local]" $@
}

log "Packing workspace into archive to transfer onto remote machine."
tar cjvf /tmp/workspace.tar.bz2 --exclude .git .

remote_command=<< EOF
set -e

log() {
  echo ">> [remote]" $@
}

cleanup() {
  log "Removing workspace..."
  rm -rf "\$HOME/workspace"
}

log "Creating workspace directory..."
mkdir "$$HOME/workspace"
trap cleanup EXIT

log "Unpacking workspace..."
tar -C "$$HOME/workspace" xjv

log "Launching docker-compose..."
COMPOSE_PROJECT="$DOCKER_COMPOSE_PREFIX"
COMPOSE_FILENAME="$DOCKER_COMPOSE_FILENAME"
cd $$HOME/workspace
docker-compose up -d
EOF

echo ">> [local] Connecting to remote host."
ssh -i <(echo "$SSH_PRIVATE_KEY") \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "$SSH_USER@$SSH_HOST" -p "$SSH_PORT" \
  "$remote_command"
