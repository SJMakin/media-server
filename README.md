# media-server

Quick setup of pi. v2.x

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
   git clone git@github.com:SJMakin/media-server.git /opt/media-server
   cd /opt/media-server
   chmod +x docker-compose.yml
   ```
   It is a best practice to place Docker Compose files in `/opt`.

3. **Mount external USB hard drive**

   Find the UUID of the drive using the following command:

   ```bash
   lsblk -o NAME,UUID
   ```
   Look for your external USB hard drive in the output and note the corresponding UUID.
   
   Edit `/etc/fstab` to include:
   ```bash
   UUID=0E340C47340C33ED /mnt ntfs-3g defaults,nofail 0 2
   ```
   Then mount the drive:
   ```bash
   sudo mount -a
   ```

5. **Install Samba and configure shared folder**
   a. Install Samba:
   ```bash
   sudo apt update
   sudo apt install samba
   ```
   
   b. Edit `/etc/samba/smb.conf`:
   ```bash
   sudo nano /etc/samba/smb.conf
   ```
   
   Add the following to the end of the `smb.conf` file:
   ```ini
   [media]
   path = /mnt
   available = yes
   valid users = pi
   read only = no
   browsable = yes
   public = yes
   writable = yes
   ```

   c. Create the system user (if not already existing):
   ```bash
   sudo adduser pi
   ```

   d. Set a Samba password for the user:
   ```bash
   sudo smbpasswd -a pi
   sudo smbpasswd -e pi
   ```

   e. Restart Samba:
   ```bash
   sudo systemctl restart smbd
   ```

6. **Firewall configuration**
   ```bash
   sudo ufw allow OpenSSH
   sudo ufw allow 8112/tcp
   sudo ufw allow 9117/tcp
   sudo ufw allow 8989/tcp
   sudo ufw allow 7878/tcp
   sudo ufw enable
   ```

**Docker Compose Usage:**

1. **Start the services:**
   ```bash
   docker compose up -d --force-recreate
   ```

2. **Update the services:**
   ```bash
   docker compose pull
   docker compose up -d --force-recreate
   ```

3. **Stop the services:**
   ```bash
   docker compose down --remove-orphans
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
