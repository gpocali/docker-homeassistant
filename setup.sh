#!/bin/sh

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (or with sudo)."
  exit 1
fi

# --- CONFIGURATION ---
# Update this URL if you push this to a GitHub repository later
RAW_REPO_URL="https://raw.githubusercontent.com/gpocali/docker-homeassistant/main"
COMPOSE_DIR="/opt/homeassistant"
# ---------------------

install_dependencies() {
  echo "Starting installation..."

  # 1. Update package list and install Docker and Docker Compose
  echo "Installing Docker and Docker Compose..."
  apk update
  apk add docker docker-cli-compose

  # 2. Enable and start Docker
  echo "Enabling and starting Docker service..."
  rc-update add docker boot
  rc-service docker start

  # 3. Setup the Home Assistant Environment & Files
  echo "Setting up application directory at $COMPOSE_DIR..."
  mkdir -p "$COMPOSE_DIR"

  echo "Downloading or copying docker-compose.yml..."
  if [ -f "./docker-compose.yml" ]; then
    cp ./docker-compose.yml "$COMPOSE_DIR/docker-compose.yml"
  else
    wget -qO "$COMPOSE_DIR/docker-compose.yml" "$RAW_REPO_URL/docker-compose.yml"
  fi

  echo "Downloading and configuring homeassistant.init..."
  if [ -f "./homeassistant.init" ]; then
    cp ./homeassistant.init /etc/init.d/homeassistant
  else
    wget -qO /etc/init.d/homeassistant "$RAW_REPO_URL/homeassistant.init"
  fi
  chmod +x /etc/init.d/homeassistant
  
  # Add the homeassistant service to boot and start it
  rc-update add homeassistant default
  rc-service homeassistant start

  # 4. Setup Resilient MOTD / Login Prompt
  echo "Setting up login instructions..."
  
  # A. Add to the static MOTD (if not already there)
  if ! grep -q "Home Assistant Service" /etc/motd 2>/dev/null; then
    echo "" >> /etc/motd
    echo "--- Home Assistant Service Commands ---" >> /etc/motd
    echo "Manage: rc-service homeassistant {start|stop|restart|status}" >> /etc/motd
    echo "Debug:  rc-service homeassistant {shell|logs|update}" >> /etc/motd
    echo "---------------------------------------" >> /etc/motd
  fi

  # B. Create the dynamic fallback script
  cat << 'EOF' > /etc/profile.d/homeassistant_motd.sh
#!/bin/sh
# If the static MOTD was overwritten, print the instructions dynamically
if ! grep -q "Home Assistant Service" /etc/motd 2>/dev/null; then
    echo ""
    echo "--- Home Assistant Service Commands ---"
    echo "Manage: rc-service homeassistant {start|stop|restart|status}"
    echo "Debug:  rc-service homeassistant {shell|logs|update}"
    echo "---------------------------------------"
fi
EOF
  chmod +x /etc/profile.d/homeassistant_motd.sh

  echo "------------------------------------------------------"
  echo "Installation Complete!"
  echo "The Home Assistant service has been started and enabled on boot."
  echo "Run 'rc-service homeassistant restart' after making configuration changes."
  echo "------------------------------------------------------"
}

uninstall_dependencies() {
  echo "Starting uninstallation process..."

  # 1. Stop and disable the homeassistant service
  if [ -f "/etc/init.d/homeassistant" ]; then
    echo "Stopping and removing homeassistant init service..."
    rc-service homeassistant stop 2>/dev/null
    rc-update del homeassistant default 2>/dev/null
    rm -f /etc/init.d/homeassistant
  fi

  # 2. Prompt for dependency removal
  echo ""
  echo "The Home Assistant service has been stopped and disabled."
  read -p "Do you also want to uninstall shared dependencies (Docker, Docker Compose)? (y/N): " remove_deps

  if [ "$remove_deps" = "y" ] || [ "$remove_deps" = "Y" ]; then
    echo "Stopping and disabling Docker service..."
    rc-service docker stop
    rc-update del docker boot

    echo "Removing packages (docker, docker-cli-compose)..."
    apk del docker docker-cli-compose

    echo "Dependencies removed."
  else
    echo "Shared dependencies were left intact."
  fi

  # 3. Clean up MOTD and Login Scripts
  echo "Cleaning up login instructions..."
  if grep -q "Home Assistant Service" /etc/motd 2>/dev/null; then
    sed -i '/--- Home Assistant Service Commands ---/,/---------------------------------------/d' /etc/motd
  fi
  rm -f /etc/profile.d/homeassistant_motd.sh

  echo "------------------------------------------------------"
  echo "Uninstallation Complete!"
  echo "Note: Application files in $COMPOSE_DIR and /mnt/appdata/homeassistant are left intact."
  echo "------------------------------------------------------"
}

# Command line argument parsing
case "$1" in
  --install)
    install_dependencies
    ;;
  --uninstall)
    uninstall_dependencies
    ;;
  *)
    echo "Usage: $0 {--install|--uninstall}"
    exit 1
    ;;
esac