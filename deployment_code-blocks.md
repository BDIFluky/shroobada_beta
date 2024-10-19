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
read -p "Enter new SSH port: " sshPort && sudo sed -i "s/^#Port 22/Port $sshPort/" /etc/ssh/sshd_config && sudo systemctl restart ssh;
```

# Setup Service Account
```bash
shroober=chimken
sudo useradd -r -s /usr/sbin/nologin -d /var/lib/$shroober -m $shroober

nextUID=$(awk -F: '{print $2 + $3}' "/etc/subuid" | sort -n | tail -n1)
sudo usermod --add-subuids "$nextUID-$((nextUID + 65535))" "$shroober"

nextGID=$(awk -F: '{print $2 + $3}' "/etc/subgid" | sort -n | tail -n1)
sudo usermod --add-subgids "$nextGID-$((nextGID + 65535))" "$(sudo -u $shroober bash -c "id -g -n")"

sudo loginctl enable-linger $shroober
```

# Clone Project & Enable Scripts
```bash
shrooAPDir=~/shroobada;
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
shrooAPDir=~/shroobada;
for file in $shrooAPDir/script_res/functions/*; do while IFS= read -r line; do echo "$line" >> ~/.bash_funcs; done < "$file"; echo "export $(basename $file)" >> ~/.bash_funcs ; done;

source ~/.bashrc;
```

# Setup Exports
```bash
shrooAPDir=~/shroobada;
for file in $shrooAPDir/script_res/exports/*; do while IFS= read -r line; do [[ -n "$line" ]] && aexport "$line"; done < "$file"; done;

source ~/.bashrc;
```

# Setup Aliases
```bash
for file in $shrooAPDir/script_res/aliases/*; do while IFS= read -r line; do [[ -n "$line" ]] && aalias "$line"; done < "$file"; done;

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

# Install Required Packages
```bash
for file in $shrooAPDir/script_res/required_packages/*; do xargs -a $file sudo DEBIAN_FRONTEND=noninteractive apt install -y ; done;
```

# Copy to Service Account
```bash
cd $shrooAPDir/.. && sudo find . -type f -regex ".*compose.*yml" -exec cp --preserve --parents {} $shrooHPDir \;
cp $shrooAPDir/script_res/shrooVars $shrooHPDir

sudo chown -R $shroober:$shrooA $shrooHPDir && sudo chmod 0770 $shrooHPDir
```

# Install Podman
```bash
podman_latest_version=$(curl -ks https://api.github.com/repos/containers/podman/releases/latest | awk '/tag_name/ {print $2}' | sed -r 's/"|,//g');
# -c http.sslVerify=false
git clone -b $podman_latest_version https://github.com/containers/podman/ $shrooPDir/podman;
cd $shrooPDir/podman/;
make BUILDTAGS="systemd selinux seccomp" PREFIX=/usr;
sudo make install PREFIX=/usr;
podman version;

cd;
sudo rm -r $shrooPDir/podman;
[ ! -d /etc/containers/ ] && sudo mkdir /etc/containers 
[ ! -f /etc/containers/policy.json ] && echo -e '{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ]
}
' | sudo tee -a /etc/containers/policy.json;

sudo -u $shroober env XDG_RUNTIME_DIR=/run/user/$(id -u $shroober) bash -c "systemctl --user start podman.socket && systemctl --user status podman.socket && cd $shrooHPDir && podman run quay.io/podman/hello"
#systemctl --user start podman.socket;
#systemctl --user enable podman.socket;
#systemctl --user status podman.socket;

#podman run quay.io/podman/hello
```

# Install Compose Plugin
```bash
cd;
docker_downs_url="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/"
needed_component="docker-compose-plugin"
# --no-check-certificate
echo "${docker_downs_url}$(curl -s $docker_downs_url | grep -oP "${needed_component}.*[.]deb"  | cut -d "\"" -f 1 | sort -V | tail -1)" | wget -O ${needed_component}.deb -i -
sudo dpkg -i needed_component.deb
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
sudo cp $shrooAPDir/traefik/traefik.yml $shrooTraefikDir

sudo chown -R  $shroober:$shrooA $shrooTraefikLogDir $shrooTraefikDir && sudo chmod 0770 $shrooTraefikLogDir $shrooTraefikDir
sudo chmod 0770 $shrooTraefikLogDir $shrooTraefikDir && sudo chmod 0770 $shrooTraefikLogDir $shrooTraefikDir
#sudo chown -R  $shroober:$shrooA $shrooTraefikDir;
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

sudo chown -R $shroober:$shrooA $shrooAuthDir $shrooAuthDB && sudo chmod 0770 $shrooAuthDir $shrooAuthDB
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

sudo chown -R $shroober:$shrooA $shrooGuacDir $shrooGuacDB && sudo chmod 0770 $shrooGuacDir $shrooGuacDB
```

# Fire in the Hole
```bash
sudo -u $shroober env  bash -c "cd $shrooCPDir && podman compose up -d"
docker inspect <container_name_or_id> --format '{{.HostConfig.UsernsMode}}'
```

# Purge
```bash
sudo rm -r $HOME/.bash_aliases $HOME/.bash_funcs $HOME/.bash_exports $HOME/shroobada $shrooTraefikDir $shrooTraefikLogDir $shrooAuthDir $shrooAuthDB $shrooGuacDir $shrooGuacDB
sudo userdel -f -r $shroober
```


# guac shit
```bash
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > initdb.sql
sed -i -e 's/guacadmin/fluky/' -e '/decode/d' initdb.sql

```

# 
```bash

```
