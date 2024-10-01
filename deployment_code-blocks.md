# Primum
```bash
adminUN=$(id -u -n)
export adminUN
echo -n "root "
su - -c "sed -i '/cdrom/d' /etc/apt/sources.list; apt update; apt upgrade -y;apt install -y git sudo;usermod -aG sudo $adminUN";
echo -n "$adminUN ";
su -p $adminUN;
[ ! -f ~/.bash_aliases ] && touch ~/.bash_aliases && echo '[ -f ~/.bash_aliases ] && . ~/.bash_aliases' >> ~/.bashrc;
[ ! -f ~/.bash_exports ] && touch ~/.bash_exports && echo '[ -f ~/.bash_exports ] && . ~/.bash_exports' >> ~/.bashrc;
[ ! -f ~/.bash_funcs ] && touch ~/.bash_funcs && echo '[ -f ~/.bash_funcs ] && . ~/.bash_funcs' >> ~/.bashrc;
[[ ":$PATH:" == *":/sbin:"* ]] && echo 'export PATH=$PATH:/sbin' >> ~/.bash_exports;
source ~/.bashrc
```

# Setup Functions
```bash
echo -e "function aalias { [ ! -z \"\$1\" ] && echo -e "alias \"\$1\"" >> ~/.bash_aliases; };\nexport -f aalias" >> ~/.bash_funcs;
echo -e "function aexport { [ ! -z \"\$1\" ] && echo -e "export \"\$1\"" >> ~/.bash_exports; };\nexport -f aexport" >> ~/.bash_funcs;
echo -e "function dcup { docker compose "$@" up -d };\nexport -f dcup" >> ~/.bash_funcs;
source ~/.bashrc;
```

# Setup Aliases
```bash
aalias "sbrc='source ~/.bashrc'";

aalias "del='rm -r'";
aalias "install='sudo apt install -y'";
aalias "..='cd ..'";
aalias "h='history'";
aalias "hg='history | grep'";

aalias "lsd='lsd --color=always -h'";
aalias "la='lsd -a'";
aalias "lat='la --tree'";
aalias "lt='lsd --tree'";
aalias "lta='lt -a'";
aalias "ll='lsd -l'";
aalias "lla='la -l'";
aalias "llt='lt -l'";
aalias "llta='llt -a'";
aalias "llat='lla --tree'";

aalias "vcmp='vim compose.yml'";
aalias "dps='docker ps'";
aalias "dl='docker logs'";
aalias "drm='docker rm'";
#aalias "dcup='docker compose up -d'";
aalias "dcupfo='dcup -f compose.yml -f compose.override.yml'";
aalias "dcd='docker compose down'";
aalias "dcdo='docker compose down'";
aalias "dcre='dcdo && dcup'";
aalias "dcrefo='dcdo && dcupfo'";
aalias "dnls='docker network ls'";
aalias "dnins='docker network inspect'";
aalias "dvls='docker volume ls'";
aalias "dvins='docker volume inspect'";

source ~/.bashrc;
``` 

# Setup apt repos
```bash
echo -e 'deb http://ftp.debian.org/debian bookworm-backports main contrib non-free\ndeb http://ftp.debian.org/debian trixie main contrib non-free\ndeb http://ftp.debian.org/debian sid main contrib non-free' | sudo tee -a /etc/apt/sources.list.d/added_repos.list;
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

# Install Docker
```bash
cd;
mkdir docker_downs;
docker_downs_url="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/"
needed_components=("containerd.io" "docker-ce" "docker-ce-cli" "docker-buildx-plugin" "docker-compose-plugin")
for component in "${needed_components[@]}"
do
  echo "${docker_downs_url}$(curl -s $docker_downs_url | grep -oP "${component}.*[.]deb"  | cut -d "\"" -f 1 | sort -V | tail -1)" | wget -O docker_downs/${component}.deb -i -
done
sudo dpkg -i docker_downs/*
sudo service docker start
sudo docker run hello-world
```

# Clone Project & Enable Scripts
```bash
shrooProjectDir=~/shroobada;
# -c http.sslVerify=false
git clone https://github.com/BDIFluky/shroobada $shrooProjectDir;

chmod +x $shrooProjectDir/script/*.sh;
#chmod +x $shrooProjectDir/fire_in_the_hole.sh;
```

# Install Essentials
```bash
xargs -a $shrooProjectDir/res/essential_packages sudo apt install -y
```

# Set Project Vars
```bash
aexport shrooProjectDir=~/shroobada;
aexport shrooTraefikDir=/etc/traefik;
aexport shrooTraefikLogDir=/var/log/traefik;

aexport shrooAuthDir=/etc/authentik;
aexport shrooAuthDB=/var/lib/authdb/

source ~/.bashrc
```

# Setup Traefik
```bash
[ ! -d $shrooTreafikLogDir ] && sudo mkdir -p $shrooTreafikLogDir;
mkdir $shrooProjectDir/traefik/letsencrypt && touch $shrooProjectDir/traefik/letsencrypt/acme.json && chmod 0600 $shrooProjectDir/traefik/letsencrypt/acme.json;
echo DOMAIN_NAME=$(hostname -d) >> $shrooProjectDir/traefik/.traefik.env;
sudo cp -rp -t /etc/ $shrooProjectDir/traefik;
mkdir -p $shrooProjectDir/log/traefik;
touch $shrooProjectDir/log/traefik/traefik.log;
touch $shrooProjectDir/log/traefik/access.log;
sudo cp -rp -t /var/log/ $shrooProjectDir/log/traefik;
sudo rm -r $shrooProjectDir/log/;
```

# Setup Auth
```bash
mkdir $shrooProjectDir/lib/authdb
sudo cp -rp -t /var/lib/ $shrooProjectDir/lib/authdb;
sudo rm -r $shrooProjectDir/lib/authdb;
cd $shrooProjectDir/authentik;
mkdir media certs custom-templates;
echo "POSTGRES_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')" >> .auth-pg.env;
echo "POSTGRES_USER=auth_db_u" >> .auth-pg.env;
echo "POSTGRES_DB=auth_db" >> .auth-pg.env;
echo "AUTHENTIK_REDIS__HOST=auth-redis" >> .auth.env;
echo "AUTHENTIK_POSTGRESQL__HOST=auth-pg" >> .auth.env;
sed -n '/^POSTGRES_USER/s/^POSTGRES_USER/AUTHENTIK_POSTGRESQL__USER/p' .auth-pg.env >> .auth.env;
#echo "AUTHENTIK_POSTGRESQL__USER=auth_db_u" >> .auth.env;
sed -n '/^POSTGRES_DB/s/^POSTGRES_DB/AUTHENTIK_POSTGRESQL__NAME/p' .auth-pg.env >> .auth.env;
#echo "AUTHENTIK_POSTGRESQL__NAME=auth_db" >> .auth.env;
sed -n '/^POSTGRES_PASSWORD/s/^POSTGRES_PASSWORD/AUTHENTIK_POSTGRESQL__PASSWORD/p' .auth-pg.env >> .auth.env;
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')" >> .auth.env;
echo "AUTHENTIK_BOOTSTRAP_PASSWORD=Chang3M3n0w" >> .auth.env;
echo "AUTHENTIK_ERROR_REPORTING__ENABLED=true" >> .auth.env;
```

# Sync
```bash
sudo rsync -hau --progress --exclude-from=$shrooProjectDir/.rsync.ignore $shrooProjectDir/ /etc/
```

# Fire in the Hole
```bash
docker compose -f $shrooProjectDir/compose.yml up -d
```

# Check Hostname Attributes
```bash
cd $shrooProjectDir;
./script/check_hostname_att.sh
```

# Setup Interfaces
```bash

```

# Setup NAT
```bash
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
```

# Nav to Proj
```bash
cdpd
```

# 
```bash

```
