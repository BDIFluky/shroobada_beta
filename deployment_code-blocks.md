# Primum
```bash
adminUN=$(id -u -n)
export adminUN;
echo -n "root ";
su - -c "sed -i '/cdrom/d' /etc/apt/sources.list; apt update; apt upgrade -y;apt install -y curl git sudo;usermod -aG sudo $adminUN";
echo -n "$adminUN ";
su -p $adminUN;
read -p "Enter new SSH port: " sshPort && sudo sed -i 's/^#Port 22/Port $sshPort/' /etc/ssh/sshd_config && sudo systemctl restart ssh;
[[ ":$PATH:" == *":/sbin:"* ]] && echo 'export PATH=$PATH:/sbin' >> ~/.bashrc;
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

# Setup .bashrc
```bash
bashFiles=(~/.bash_aliases ~/.bash_exports ~/.bash_funcs);
for file in "${bashFiles[@]}"; do source_line="[ -f $file ] && . $file"; [ ! -f "$file" ] && touch "$file" && echo "$source_line" >> ~/.bashrc || ! grep -q "$source_line" ~/.bashrc && echo "$source_line" >> ~/.bashrc; done;

source ~/.bashrc
```

# Setup Functions
```bash
echo -e "function aalias { [ ! -z \"\$1\" ] && ! grep -q \"alias \\\"\$1\\\"\" ~/.bash_aliases && echo \"alias \\\"\$1\\\"\" >> ~/.bash_aliases || echo -e \"\e[33mAlias '\$1' already exists.\e[0m\"; };\nexport -f aalias" >> ~/.bash_funcs
echo -e "function aexport { [ ! -z \"\$1\" ] && ! grep -q \"export \\\"\$1\\\"\" ~/.bash_exports && echo \"export \\\"\$1\\\"\" >> ~/.bash_exports || echo -e \"\e[33mExport '\$1' already exists.\e[0m\"; };\nexport -f aexport" >> ~/.bash_funcs
#echo -e "function aexport { [ ! -z \"\$1\" ] && echo -e "export \"\$1\"" >> ~/.bash_exports; };\nexport -f aexport" >> ~/.bash_funcs;
#echo -e "function dcup { docker compose \"\$@\" up -d; };\nexport -f dcup" >> ~/.bash_funcs;
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
aalias "wdps='watch docker ps'";
aalias "dex='docker exec -it'";
aalias "dl='docker logs'";
aalias "drm='docker rm'";
aalias "dcup='docker compose up -d'";
#aalias "dcupfo='dcup -f compose.yml -f compose.override.yml'";
aalias "dcd='docker compose down'";
aalias "dcdo='docker compose down'";
aalias "dcre='dcdo && dcup'";
#aalias "dcrefo='dcdo && dcupfo'";
aalias "dnls='docker network ls'";
aalias "dnrm='docker network rm'";
aalias "dnins='docker network inspect'";
aalias "dvls='docker volume ls'";
aalias "dvrm='docker volume rm'";
aalias "dvins='docker volume inspect'";

source ~/.bashrc;
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
aexport shrooAuthDB=/var/lib/authdb;

aexport shrooGuacDir=/etc/guacamole;
aexport shrooGuacDB=/var/lib/guacdb;

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
mkdir -p $shrooProjectDir/lib/authdb
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
sed -n '/^POSTGRES_DB/s/^POSTGRES_DB/AUTHENTIK_POSTGRESQL__NAME/p' .auth-pg.env >> .auth.env;
sed -n '/^POSTGRES_PASSWORD/s/^POSTGRES_PASSWORD/AUTHENTIK_POSTGRESQL__PASSWORD/p' .auth-pg.env >> .auth.env;
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')" >> .auth.env;
echo "AUTHENTIK_BOOTSTRAP_PASSWORD=Chang3M3n0w" >> .auth.env;
echo "AUTHENTIK_ERROR_REPORTING__ENABLED=flase" >> .auth.env;
```

# Setup Guac
```bash
mkdir -p $shrooProjectDir/guacamole/drive $shrooProjectDir/guacamole/record $shrooProjectDir/lib/guacdb/init $shrooProjectDir/lib/guacdb/data
sudo cp -rp -t /var/lib/ $shrooProjectDir/lib/guacdb;
sudo rm -r $shrooProjectDir/lib/guacdb;
cd $shrooProjectDir/guacamole;

echo "POSTGRES_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')" >> .guac-pg.env;
echo "POSTGRES_USER=guac_db_u" >> .guac-pg.env;
echo "POSTGRES_DB=guac_db" >> .guac-pg.env;
echo "PGDATA=/var/lib/postgresql/data/guacamole" >> .guac-pg.env;

echo "GUACD_HOSTNAME=guacd" >> .guac.env;
echo "POSTGRES_HOSTNAME=guac-pg" >> .guac.env;
#sed -n '/^POSTGRES_USER/p' .guac-pg.env >> .guac.env;
sed -n '/^POSTGRES_USER/s/^POSTGRES_USER/POSTGRESQL_USER/p' .guac-pg.env >> .guac.env;
#sed -n '/^POSTGRES_DATABASE/p' .guac-pg.env >> .guac.env;
sed -n '/^POSTGRES_DB/s/^POSTGRES_DB/POSTGRESQL_DATABASE/p' .guac-pg.env >> .guac.env;
#sed -n '/^POSTGRES_PASSWORD/p' .guac-pg.env >> .guac.env;
sed -n '/^POSTGRES_PASSWORD/s/^POSTGRES_PASSWORD/POSTGRESQL_PASSWORD/p' .guac-pg.env >> .guac.env;
echo "OPENID_AUTHORIZATION_ENDPOINT=https://auther.boredomdidit.com:8443/application/o/authorize/" >> .guac.env;
echo "OPENID_JWKS_ENDPOINT=https://auther.boredomdidit.com:8443/application/o/guac/jwks/" >> .guac.env;
echo "OPENID_ISSUER=https://auther.boredomdidit.com:8443/application/o/guac/" >> .guac.env;
echo "OPENID_CLIENT_ID=Qif9JCKvGyb7FwToQEaCBGYfdcNgsSefD9WeoJXN" >> .guac.env;
echo "OPENID_REDIRECT_URI=https://guac.boredomndidit.com:8443" >> .guac.env;
```

# Sync
```bash
sudo rsync -hau --progress --exclude-from=$shrooProjectDir/.rsync.ignore $shrooProjectDir/ /etc/
```

# Fire in the Hole
```bash
docker compose -f $shrooProjectDir/compose.yml up -d
```

# Purge
```bash
cd;
sudo rm .bash_aliases .bash_funcs .bash_exports
sudo cp /home/test/.bashrc .bashrc
sudo rm -r shroobada/ /etc/authentik /etc/traefik /var/log/traefik/
```

# Check Hostname Attributes
```bash
cd $shrooProjectDir;
./script/check_hostname_att.sh
```

# guac shit
```bash
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > initdb.sql
sed -i -e 's/guacadmin/fluky/' -e '/decode/d' initdb.sql

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
