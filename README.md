# media-server

Quick set up of pi.

Stack:
Deluge - torrent client - port 8112
Jackett - torrent indexer - port 9117
Sonarr - tv show management - port 8989
Radarr - movie management - port 7878

Install:
Get docker / docker compose

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo apt-get install python3-pip
sudo pip3 install docker-compose

clone this repo and start! oh baby!

*Docker compose reference:*
Start: docker-compose up --force-recreate -d
Update: docker-compose pull
Stop: docker-compose down --remove-orphans || true

Pi-Hole

Road runner install:
curl -sSL https://install.pi-hole.net | bash

Setup:

Disable DCHP on router and enable on pi hole.






TODO: Add pi-hole to docker stack instead of bare metal.