
# Setup Essentials
```bash
adminUN=$(id -u -n)
export adminUN
echo -n "root "
su - -c "sed -i '/cdrom/d' /etc/apt/sources.list; apt update; apt upgrade -y;apt install -y curl vim lsd iptables-persistent git make sudo;usermod -aG sudo $adminUN";
echo -n "$adminUN ";
su -p $adminUN;
echo "export PATH=$PATH:/sbin" >> ~/.bashrc;
```

# Setup Aliases
```bash
echo -e "function palias { echo -e "alias '$1'" >> ~/.bashrc; }\nexport palias" >> ~/.bashrc;
source ~/.bashrc;

palias "sbrc='source ~/.bashrc'";
palias "ls='lsd --color=always -h'";
palias "lsa='ls -a'";
palias "lsat='lsa --tree'";
palias "lst='ls --tree'";
palias "lsta='lst -a'";
palias "ll='ls -l'";
palias "lla='lsa -l'";
palias "llt='lst -l'";
palias "llta='llt -a'";
palias "llat='lla --tree'";
palias "vcmp='vim compose.yml'";
palias "vpcmp='vim $PROJECT_DIR/compose.yml'";
palias "dcup='docker compose up -d'";
palias "dcdo='docker compose down'";
palias "dcre='dcdo && dcup'";
palias "dnls='docker network ls'";
palias "dnins='docker network inspect'";
palias "dvins='docker volume inspect'";
palias "sctludr='systemctl --user daemon-reload'";

palias "cdpd='cd $PROJECT_DIR'";

source ~/.bashrc;
``` 

# Setup apt repos
```bash
echo -e "deb http://ftp.debian.org/debian bookworm-backports main contrib non-free\ndeb http://ftp.debian.org/debian trixie main contrib non-free\ndeb http://ftp.debian.org/debian sid main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/added_repos.list;
sudo tee -a /etc/apt/preferences.d/main-priorities <<EOF
# Priority for Bookworm (Stable)
Package: *
Pin: release a=bookworm
Pin-Priority: 900

# Priority for Bookworm-backports
Package: *
Pin: release a=bookworm-backports
Pin-Priority: 700

# Priority for Trixie (Testing)
Package: *
Pin: release a=trixie
Pin-Priority: 500

# Priority for Sid (Unstable)
Package: *
Pin: release a=sid
Pin-Priority: 400
EOF

sudo apt update;
```

# Clone Project & Enable Scripts
```bash
PROJECT_DIR=$HOME/shroobada;
# -c http.sslVerify=false
git clone https://github.com/BDIFluky/shroobada $PROJECT_DIR;

chmod +x $PROJECT_DIR/script/*.sh
```


# Check Hostname Attributes
```bash
cd $PROJECT_DIR;
./script/check_hostname_att.sh
```

# Setup Interfaces
```bash

```

# Install Docker
```bash
cd
mkdir docker_downs
# download stuff from https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/
sudo dpkg -i docekr_downs/*
sudo service docker start
sudo docker run hello-world
```

# Setup Project Vars
```bash
PROJECT_DIR=$HOME/shroobada;
TRAEFIK_WDIR=/etc/traefik
TRAEFIK_LDIR=/var/log/traefik
USER_SYSD=$HOME/.config/containers/systemd/;
```

# Setup Project
```bash
[ ! -d $TRAEFIK_LDIR ] && sudo mkdir -p /var/log/traefik;
mkdir $PROJECT_DIR/traefik/letsencrypt;
touch $PROJECT_DIR/traefik/letsencrypt/acme.json;
chmod 0600 $PROJECT_DIR/traefik/letsencrypt/acme.json;
echo DOMAIN_NAME=$(hostname -d) >> $PROJECT_DIR/traefik/.traefik.env;
sudo cp -rp -t /etc/ $PROJECT_DIR/traefik
touch traefik.log;
touch access.log;
sudo cp -rp -t $TRAEFIK_LDIR access.log traefik.log;
```

# Setup Auth
```bash
[ ! -d /etc/authentik ] && sudo mkdir /etc/authentik;
echo "POSTGRES_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')" >> .auth.env
echo "POSTGRES_USER=auth_db_u" >> .auth.env
echo "POSTGRES_DB=auth_db" >> .auth.env
echo "AUTHENTIK_REDIS__HOST=auth-redis" >> .auth.env
echo "AUTHENTIK_POSTGRESQL__HOST=postgresql" >> .auth.env
echo "AUTHENTIK_POSTGRESQL__USER=auth_db_u" >> .auth.env
echo "AUTHENTIK_POSTGRESQL__NAME=auth_db" >> .auth.env
sed -n '/^POSTGRES_PASSWORD/s/^POSTGRES_PASSWORD/AUTHENTIK_POSTGRESQL__PASSWORD/p' .auth.env >> .auth.env
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')" >> .auth.env
echo "AUTHENTIK_ERROR_REPORTING__ENABLED=true" >> .auth.env
echo "AUTHENTIK_BOOTSTRAP_PASSWORD=Chang3M3n0w" >> .auth.env
sudo mv .auth.env /etc/authentik/
```

# Setup NAT
#http://<your server's IP or hostname>:9000/if/flow/initial-setup/
```bash
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
```

# Nav to Proj
```bash
cdpd
```

# Fire in the Hole
```bash
docker compose -f $PROJECT_DIR/compose.yml up
```

# 
```bash

```
