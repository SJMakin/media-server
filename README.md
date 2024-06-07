# media-server

Quick setup of pi. v2.0

**Stack:**

* Deluge - torrent client - port 8112
* Jackett - torrent indexer - port 9117
* Sonarr - TV show management - port 8989
* Radarr - movie management - port 7878

**Install:**

1. **Install Docker**
   Refer to [Docker's official documentation](https://docs.docker.com/engine/install/ubuntu/) for installation steps.

2. **Clone repository and set up Docker compose file**
   ```bash
   git clone <your-repo-url> /opt/media-server
   cd /opt/media-server
   chmod +x docker-compose.yml
   ```
   It is a best practice to place Docker Compose files in `/opt`.

3. **Mount external USB hard drive**
   Edit `/etc/fstab` to include:
   ```bash
   UUID=<UUID of the drive> /mnt/usbdrive ext4 defaults,nofail 0 2
   ```
   Then mount the drive:
   ```bash
   sudo mount -a
   ```

4. **Install Samba**
   ```bash
   sudo apt update
   sudo apt install samba
   sudo nano /etc/samba/smb.conf
   ```
   Add the following to the end of the `smb.conf` file:
   ```bash
   [media]
   path = /mnt/usbdrive
   available = yes
   valid users = <your-username>
   read only = no
   browsable = yes
   public = yes
   writable = yes
   ```
   Restart Samba:
   ```bash
   sudo systemctl restart smbd
   ```

5. **Firewall configuration**
   ```bash
   sudo ufw allow OpenSSH
   sudo ufw allow 8112/tcp
   sudo ufw allow 9117/tcp
   sudo ufw allow 8989/tcp
   sudo ufw allow 7878/tcp
   sudo ufw enable
   ```

**Docker Compose commands:**

Start:
```bash
docker-compose up --force-recreate -d
```

Update:
```bash
docker-compose pull
```

Stop:
```bash
docker-compose down --remove-orphans || true
```

**Pi-Hole**

Quick installation:
```bash
curl -sSL https://install.pi-hole.net | bash
```

Setup:

Disable DHCP on your router and enable it on Pi-hole.

**TODO:**

Add Pi-hole to the Docker stack instead of bare metal.
