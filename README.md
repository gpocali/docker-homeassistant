# Home Assistant OpenRC Docker Deployment

This project runs a highly optimized Home Assistant container using Docker Compose. It utilizes the `linuxserver/homeassistant` image and is specifically configured with `host` networking to ensure seamless auto-discovery (mDNS) of your local smart home devices.

Instead of running a standalone Docker command, this implementation registers Home Assistant as a native background service on your system, complete with persistent storage mapping and local timezone synchronization.

## Requirements
* **Host OS**: Alpine Linux (The automated installer is built specifically for Alpine's OpenRC init system).

## Quick Installation

You can install the dependencies, configure Docker, pull the prebuilt container, and set up the background service by running a single command as root:

```bash
wget -qO- https://raw.githubusercontent.com/gpocali/docker-homeassistant/main/setup.sh | sh -s -- --install

```

### What this script does:

1. Installs and enables Docker and Docker Compose via the `apk` package manager.
2. Downloads the `docker-compose.yml` to `/opt/homeassistant/`.
3. Installs a custom OpenRC init script so the service starts cleanly on boot.
4. Adds helpful management commands to your terminal's login screen (MOTD).

## Configuration

After installation, the service will start automatically using default values. The container's persistent data is stored safely on your host machine at `/mnt/appdata/homeassistant`.

1. Open the compose file to verify or change base settings:

```bash
nano /opt/homeassistant/docker-compose.yml

```

2. Update the environment variables (if needed):

* `TZ`: Your local timezone (Default is `America/New_York`).
* `PUID` / `PGID`: The user and group ID for file permissions (Default is `1000`).

3. **Changing the Port (Host Networking)**: Because this project uses `network_mode: "host"` to allow Home Assistant to discover smart devices, standard Docker port mappings in the compose file are ignored. The default port is **8123**. To change it, edit the generated configuration file:

```bash
nano /mnt/appdata/homeassistant/configuration.yaml

```

Add the following lines to the bottom:

```yaml
http:
  server_port: 8080

```

4. Restart the service to apply changes:

```bash
rc-service homeassistant restart

```

## Service Management

Because this project is registered as a native Alpine service, you can manage it using standard `rc-service` commands:

* **Start the service**: `rc-service homeassistant start`
* **Stop the service**: `rc-service homeassistant stop`
* **Restart the service**: `rc-service homeassistant restart`
* **Check status**: `rc-service homeassistant status`

### Troubleshooting and Logs

If you need to diagnose issues or perform maintenance, the init script provides custom interactive commands:

* **View Real-Time Logs**: `rc-service homeassistant logs`
*(Streams standard output. Press `Ctrl+C` to exit)*.
* **Open a Shell**: `rc-service homeassistant shell`
*(Drops you into a bash prompt inside the running container to check configs or test connectivity. Type `exit` to return)*.
* **Update Container**: `rc-service homeassistant update`
*(Automatically pulls the latest `linuxserver` image and recreates the container without losing your configuration).*

## Uninstallation

To safely stop the container, remove the init scripts, and clean up your login screen, run the uninstallation command:

```bash
wget -qO- https://raw.githubusercontent.com/gpocali/docker-homeassistant/main/setup.sh | sh -s -- --uninstall

```

* During uninstallation, you will be prompted and can choose whether you want to completely remove Docker from your system or leave it intact for other applications.
* Your persistent Home Assistant configuration in `/mnt/appdata/homeassistant` and the `docker-compose.yml` file in `/opt/homeassistant` are **not deleted**.
