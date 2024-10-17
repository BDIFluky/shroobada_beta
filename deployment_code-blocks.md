# Primum
```bash
adminUN=$(id -u -n)
export adminUN;
echo -n "root ";
su - -c "sed -i '/cdrom/d' /etc/apt/sources.list; apt update; apt upgrade -y;apt install -y git sudo;usermod -aG sudo $adminUN";
echo -n "$adminUN ";
su -p $adminUN;
[[ ! ":$PATH:" == *":/sbin:"* ]] && ! grep -q 'export PATH=$PATH:/sbin' ~/.bashrc && echo 'export PATH=$PATH:/sbin' >> ~/.bashrc;
source ~/.bashrc;
```

# Well well well
```bash
read -p "Enter new SSH port: " sshPort && sudo sed -i 's/^#Port 22/Port $sshPort/' /etc/ssh/sshd_config && sudo systemctl restart ssh;
```

# Clone Project & Enable Scripts
```bash
shrooPDir=~/shroobada;
# -c http.sslVerify=false
git clone https://github.com/BDIFluky/shroobada $shrooPDir;
```

# Setup .bashrc
```bash
bashFiles=(~/.bash_aliases ~/.bash_exports ~/.bash_funcs);
for file in "${bashFiles[@]}"; do source_line="[ -f $file ] && . $file"; [ ! -f "$file" ] && touch "$file"; grep -q "$source_line" ~/.bashrc || echo "$source_line" >> ~/.bashrc; done

source ~/.bashrc
```

# Setup Functions
```bash
shrooPDir=~/shroobada;
for file in $shrooPDir/script_res/functions/*; do while IFS= read -r line; do echo "$line" >> ~/.bash_funcs; done < "$file"; echo "export $(basename $file)" >> ~/.bash_funcs ; done;

source ~/.bashrc;
```

# Setup Service Account
```bash
sudo useradd -r -s /usr/sbin/nologin -d /var/lib/$shroober -m $shroober

nextUID=$(awk -F: '{print $2 + $3}' "/etc/subuid" | sort -n | tail -n1)
sudo usermod --add-subuids "$nextUID-$((nextUID + 65535))" "$shroober"

nextGID=$(awk -F: '{print $2 + $3}' "/etc/subgid" | sort -n | tail -n1)
sudo usermod --add-subgids "$nextGID-$((nextGID + 65535))" "$(sudo -u $shroober bash -c "id -g -n")"

sudo loginctl enable-linger $shroober

cd $shrooPDir/.. && sudo find . -type f -regex ".*compose.*yml" -exec cp --preserve --parents {} $shrooHPDir \;
sudo chown -R $shroober $shrooCPDir

#sudo -Eu $shroober env XDG_RUNTIME_DIR=/run/user/$(id -u $shroober) HOME=/var/lib/chimken bash -c "cd $HOME/shroobada/traefik; podman compose -f traefik-compose.yml up -d whoami"
```

# Setup Exports
```bash
shrooPDir=~/shroobada;
for file in $shrooPDir/script_res/exports/*; do while IFS= read -r line; do [[ -n "$line" ]] && aexport "$line"; done < "$file"; done;

source ~/.bashrc;
```

# Setup Aliases
```bash
for file in $shrooPDir/script_res/aliases/*; do while IFS= read -r line; do [[ -n "$line" ]] && aalias "$line"; done < "$file"; done;

source ~/.bashrc;
```

# Install Required Packages
```bash
for file in $shrooPDir/script_res/required_packages/*; do xargs -a $file sudo apt install -y ; done;
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

# Install Podman
```bash
DEBIAN_FRONTEND=noninteractive sudo apt install -y \
  btrfs-progs \
  crun/sid \
  passt/sid \
  git \
  golang-go/bookworm-backports \
  golang-src/bookworm-backports \
  go-md2man \
  iptables \
  libassuan-dev \
  libbtrfs-dev \
  libc6-dev \
  libdevmapper-dev \
  libglib2.0-dev \
  libgpgme-dev \
  libgpg-error-dev \
  libprotobuf-dev \
  libprotobuf-c-dev \
  libseccomp-dev \
  libselinux1-dev \
  libsystemd-dev \
  netavark \
  pkg-config \
  uidmap \
  conmon \
  make

podman_latest_version=$(curl -ks https://api.github.com/repos/containers/podman/releases/latest | awk '/tag_name/ {print $2}' | sed -r 's/"|,//g');
# -c http.sslVerify=false
git clone -b $podman_latest_version https://github.com/containers/podman/ $shrooPDir/podman;
cd $shrooPDir/podman/;
make BUILDTAGS="systemd selinux seccomp" PREFIX=/usr;
sudo make install PREFIX=/usr;
podman version;

sudo rm -r podman;
[ ! -d /etc/containers/ ] && sudo mkdir /etc/containers 
[ ! -f /etc/containers/policy.json ] && echo -e '{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ]
}
' | sudo tee -a /etc/containers/policy.json;

sudo -u $shroober env XDG_RUNTIME_DIR=/run/user/$(id -u $shroober) bash -c "systemctl --user start podman.socket && systemctl --user enable podman.socket && systemctl --user status podman.socket && podman run quay.io/podman/hello"
#systemctl --user start podman.socket;
#systemctl --user enable podman.socket;
#systemctl --user status podman.socket;

#podman run quay.io/podman/hello
```


# Install Docker
```bash
cd;
mkdir docker_downs;
docker_downs_url="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/"
needed_components=("containerd.io" "docker-ce" "docker-ce-cli" "docker-buildx-plugin" "docker-compose-plugin" "docker-ce-rootless-extras")
# --no-check-certificate
for component in "${needed_components[@]}"
do
  echo "${docker_downs_url}$(curl -s $docker_downs_url | grep -oP "${component}.*[.]deb"  | cut -d "\"" -f 1 | sort -V | tail -1)" | wget -O docker_downs/${component}.deb -i -
done
sudo dpkg -i docker_downs/*
/usr/bin/dockerd-rootless-setuptool.sh install
systemctl --user start docker
systemctl --user enable docker
sudo loginctl enable-linger $(whoami)
docker run hello-world
```

# Setup Traefik
```bash
[ ! -d $shrooTraefikLogDir ] && sudo mkdir -p $shrooTraefikLogDir;
sudo touch $shrooTraefikLogDir/traefik.log;
sudo touch $shrooTraefikLogDir/access.log;

sudo mkdir -p $shrooTraefikDir/letsencrypt && sudo touch $shrooTraefikDir/letsencrypt/acme.json && sudo chmod 0600 $shrooTraefikDir/letsencrypt/acme.json;
echo DOMAIN_NAME=$(hostname -d) | sudo tee -a $shrooTraefikDir/.traefik.env;
read -p 'Provider email: ' email && echo "PROVIDER_EMAIL=$email" | sudo tee -a $shrooTraefikDir/.traefik.env;
read -sp 'Provider API Token: ' token && echo "INFOMANIAK_ACCESS_TOKEN=$token" | sudo tee -a $shrooTraefikDir/.traefik.env;

sudo chown -R $shroober $shrooTraefikLogDir;
sudo chown -R $shroober $shrooTraefikDir;
```

# Setup Auth
```bash
sudo mkdir -p $shrooAuthDB
sudo mkdir -p $shrooAuthDir/media $shrooAuthDir/certs $shrooAuthDir/custom-templates;

sudo mkdir -p $shrooAuthDir
echo "POSTGRES_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')" | sudo tee -a $shrooAuthDir/.auth-pg.env;
echo "POSTGRES_USER=auth_db_u" | sudo tee -a $shrooAuthDir/.auth-pg.env;
echo "POSTGRES_DB=auth_db" | sudo tee -a $shrooAuthDir/.auth-pg.env;

echo "AUTHENTIK_REDIS__HOST=auth-redis" | sudo tee -a $shrooAuthDir/.auth.env;
echo "AUTHENTIK_POSTGRESQL__HOST=auth-pg" | sudo tee -a $shrooAuthDir/.auth.env;
sed -n '/^POSTGRES_USER/s/^POSTGRES_USER/AUTHENTIK_POSTGRESQL__USER/p' $shrooAuthDir/.auth-pg.env | sudo tee -a $shrooAuthDir/.auth.env;
sed -n '/^POSTGRES_DB/s/^POSTGRES_DB/AUTHENTIK_POSTGRESQL__NAME/p' $shrooAuthDir/.auth-pg.env | sudo tee -a $shrooAuthDir/.auth.env;
sed -n '/^POSTGRES_PASSWORD/s/^POSTGRES_PASSWORD/AUTHENTIK_POSTGRESQL__PASSWORD/p' .$shrooAuthDir/.auth-pg.env | sudo tee -a $shrooAuthDir/.auth.env;
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')" | sudo tee -a $shrooAuthDir/.auth.env;
echo "AUTHENTIK_BOOTSTRAP_PASSWORD=Chang3M3n0w" | sudo tee -a $shrooAuthDir/.auth.env;
echo "AUTHENTIK_ERROR_REPORTING__ENABLED=flase" | sudo tee -a $shrooAuthDir/.auth.env;

sudo chown -R $shroober $shrooAuthDir $shrooAuthDB
```

# Setup Guac
```bash
sudo mkdir -p $shrooGuacDir/drive $shrooGuacDir/record $shrooGuacDB/init $shrooGuacDB/data

cd $shrooGuacDir;

echo "POSTGRES_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')" | sudo tee -a .guac-pg.env;
echo "POSTGRES_USER=guac_db_u" | sudo tee -a .guac-pg.env;
echo "POSTGRES_DB=guac_db" | sudo tee -a .guac-pg.env;
echo "PGDATA=/var/lib/postgresql/data/guacamole" | sudo tee -a .guac-pg.env;

echo "GUACD_HOSTNAME=guacd" | sudo tee -a .guac.env;
echo "POSTGRES_HOSTNAME=guac-pg" | sudo tee -a .guac.env;
sed -n '/^POSTGRES_USER/s/^POSTGRES_USER/POSTGRESQL_USER/p' .guac-pg.env | sudo tee -a .guac.env;
sed -n '/^POSTGRES_DB/s/^POSTGRES_DB/POSTGRESQL_DATABASE/p' .guac-pg.env | sudo tee -a .guac.env;
sed -n '/^POSTGRES_PASSWORD/s/^POSTGRES_PASSWORD/POSTGRESQL_PASSWORD/p' .guac-pg.env | sudo tee -a .guac.env;
echo "OPENID_AUTHORIZATION_ENDPOINT=https://auther.boredomdidit.com:8443/application/o/authorize/" | sudo tee -a .guac.env;
echo "OPENID_JWKS_ENDPOINT=https://auther.boredomdidit.com:8443/application/o/guac/jwks/" | sudo tee -a .guac.env;
echo "OPENID_ISSUER=https://auther.boredomdidit.com:8443/application/o/guac/" | sudo tee -a .guac.env;
echo "OPENID_CLIENT_ID=Qif9JCKvGyb7FwToQEaCBGYfdcNgsSefD9WeoJXN" | sudo tee -a .guac.env;
echo "OPENID_REDIRECT_URI=https://guac.boredomndidit.com:8443" | sudo tee -a .guac.env;

sudo chown -R $shroober $shrooGuacDir $shrooGuacDB
```

# Sync
```bash
sudo rsync -hau --progress --exclude-from=$shrooPDir/.rsync.ignore $shrooPDir/ /etc/
```

# Fire in the Hole
```bash
docker compose -f $shrooPDir/compose.yml up -d
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
cd $shrooPDir;
./script/check_hostname_att.sh
```

# guac shit
```bash
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > initdb.sql
sed -i -e 's/guacadmin/fluky/' -e '/decode/d' initdb.sql

```

# Go Install Raw
```bash
go_latest_version=$(curl -s https://go.dev/dl/ | grep -oP 'go[0-9]+\.[0-9]+(\.[0-9]+)?\.linux-amd64\.tar\.gz' | head -n 1)
wget https://go.dev/dl/$go_latest_version
sudo tar -C /opt/ -xzf $go_latest_version
[[ ":$PATH:" == *":/opt/go/bin:"* ]] && echo 'export PATH=$PATH:/opt/go/bin' >> ~/.bashrc;
source ~/.bashrc;
```

# Setup Functions Raw
```bash
echo -e "function aalias { [ ! -z \"\$1\" ] && ! grep -q \"alias \\\"\$1\\\"\" ~/.bash_aliases && echo \"alias \\\"\$1\\\"\" >> ~/.bash_aliases || echo -e \"\e[33mAlias '\$1' already exists.\e[0m\"; };\nexport -f aalias" >> ~/.bash_funcs
echo -e "function aexport { [ ! -z \"\$1\" ] && ! grep -q \"export \\\"\$1\\\"\" ~/.bash_exports && echo \"export \\\"\$1\\\"\" >> ~/.bash_exports || echo -e \"\e[33mExport '\$1' already exists.\e[0m\"; };\nexport -f aexport" >> ~/.bash_funcs

source ~/.bashrc;
```

# Setup Aliases Raw
```bash
aalias sbrc='source ~/.bashrc';
aalias vbrc='vim ~/.bashrc';

aalias del='rm -r';
aalias install='sudo apt install -y';
aalias ..='cd ..';
aalias h='history';
aalias hg='history | grep';

aalias lsd='lsd --color=always -h';
aalias la='lsd -a';
aalias lat='la --tree';
aalias lt='lsd --tree';
aalias lta='lt -a';
aalias ll='lsd -l';
aalias lla='la -l';
aalias llt='lt -l';
aalias llta='llt -a';
aalias llat='lla --tree';

aalias vcmp='vim compose.yml';
aalias dps='docker ps';
aalias wdps='watch docker ps';
aalias dex='docker exec -it';
aalias dl='docker logs';
aalias drm='docker rm';
aalias dcup='docker compose up -d';
aalias dcd='docker compose down';
aalias dcdo='docker compose down';
aalias dcre='dcdo && dcup';
aalias dnls='docker network ls';
aalias dnrm='docker network rm';
aalias dnins='docker network inspect';
aalias dvls='docker volume ls';
aalias dvrm='docker volume rm';
aalias dvins='docker volume inspect';

source ~/.bashrc;
```

# Set Project Vars raw
```bash
aexport shrooPDir=~/shroobada;
aexport shrooTraefikDir=/etc/traefik;
aexport shrooTraefikLogDir=/var/log/traefik;

aexport shrooAuthDir=/etc/authentik;
aexport shrooAuthDB=/var/lib/authdb;

aexport shrooGuacDir=/etc/guacamole;
aexport shrooGuacDB=/var/lib/guacdb;

source ~/.bashrc
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
