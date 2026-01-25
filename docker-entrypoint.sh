#!/bin/bash
set -e

# Start tailscaled (userspace networking for containers)
if command -v tailscaled >/dev/null 2>&1; then
  echo "Starting tailscaled..."
  tailscaled --tun=userspace-networking --state="${CLAWDBOT_STATE_DIR:-/data}/tailscale.state" --socket=/tmp/tailscaled.sock &
  sleep 1

  if [ -n "${TAILSCALE_AUTHKEY}" ]; then
    echo "Authenticating tailscale..."
    tailscale --socket=/tmp/tailscaled.sock up --authkey="${TAILSCALE_AUTHKEY}" --hostname="${TAILSCALE_HOSTNAME:-flying-jarvis}"
    if [ -n "${TAILSCALE_SERVE}" ]; then
      echo "Enabling tailscale serve..."
      tailscale --socket=/tmp/tailscaled.sock serve https / http://127.0.0.1:3000
    fi
  else
    echo "TAILSCALE_AUTHKEY not set; skipping tailscale up."
  fi
fi

# Initialize config file if it doesn't exist
CONFIG_DIR="${CLAWDBOT_STATE_DIR:-/data}"
CONFIG_FILE="$CONFIG_DIR/clawdbot.json"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Copy default config if config file doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file not found at $CONFIG_FILE"
  echo "Creating default config from template..."
  cp /app/default-config.json "$CONFIG_FILE"
  
  # Replace placeholder values with environment variables if set
  if [ -n "${DISCORD_GUILD_ID}" ]; then
    echo "Setting Discord Guild ID from environment variable..."
    sed -i "s/YOUR_GUILD_ID/${DISCORD_GUILD_ID}/g" "$CONFIG_FILE"
  fi
  
  echo "Default config created at $CONFIG_FILE"
  echo "You can customize this config via the UI or by editing the file directly"
fi

# Execute the CMD from Dockerfile
exec "$@"
