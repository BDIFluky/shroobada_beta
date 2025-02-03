# Admin Setup

```bash
adminUN=$(id -u -n)
export adminUN;
echo -n "root ";
su - -c "sed -i '/cdrom/d' /etc/apt/sources.list; apt update; apt upgrade -y;apt install -y curl git sudo vim;usermod -aG sudo $adminUN";
echo -n "$adminUN ";
su -p $adminUN;
[[ ! ":$PATH:" == *":/sbin:"* ]] && ! grep -q 'export PATH=$PATH:/sbin' ~/.bashrc && echo 'export PATH=$PATH:/sbin' >> ~/.bashrc;
source ~/.bashrc;
```
6666

# Change SSH Port

```bash
read -p "Enter new SSH port: " sshPort && sudo sed -i "s/^#Port 22/Port $sshPort/" /etc/ssh/sshd_config && sudo systemctl restart ssh;
```

# Shroober Setup

```bash
shroober=chimken
shrooberHome=/opt/shroobada
id $shroober &>/dev/null || sudo useradd -r -s /usr/sbin/nologin -d $shrooberHome -m $shroober
sudo chown -R $shroober:$(id -g -n) $shrooberHome
sudo chmod -R 0640 $shrooberHome
sudo chmod +X $shrooberHome

grep "^$shroober:" /etc/subuid || nextUID=$(awk -F: '{print $2 + $3}' "/etc/subuid" | sort -n | tail -n1) &&  sudo usermod --add-subuids "$nextUID-$((nextUID + 65535))" "$shroober"

grep "^$(id $shroober -g -n):" /etc/subgid || nextGID=$(awk -F: '{print $2 + $3}' "/etc/subgid" | sort -n | tail -n1) && sudo usermod --add-subgids "$nextGID-$((nextGID + 65535))" "$(sudo -u $shroober bash -c "id -g -n")"

sudo loginctl enable-linger $shroober
```

# Fetch Essentials Repo

```bash
shroober=chimken
export shrooberHome=$(eval echo ~$shroober)
repo=debian_scripts
# --no-check-certificate --header="Authorization: token "
sudo wget https://github.com/BDIFluky/$repo/archive/refs/heads/main.tar.gz -P $shrooberHome;
sudo tar -xf $shrooberHome/main.tar.gz -C $shrooberHome
sudo cp -r $shrooberHome/$repo-main/. $shrooberHome/
sudo rm -r $shrooberHome/$repo-main $shrooberHome/main.tar.gz
sudo chown -R $shroober:$(id -g -n) $shrooberHome
sudo find $shrooberHome/ -type d -exec chmod +x {} +

sudo chmod +x $shrooberHome/first_startup/environment_setup.sh
sudo -E $shrooberHome/first_startup/environment_setup.sh
source .bashrc
```

# Parse shrooVars

```bash
shrooVarsPath=$shrooberHome/shroobada/res/shrooVars 
temp=$(mktemp) && sed -E 's/=(.*)/=\1/g' $shrooVarsPath | while IFS= read -r line; do eval "echo \"$line\""; done > temp && mv temp $shrooVarsPath
```


# Install Podman

```bash
podman_latest_version=$(curl -ks https://api.github.com/repos/containers/podman/releases/latest | awk '/tag_name/ {print $2}' | sed -r 's/"|,//g');
# -c http.sslVerify=false
git clone -b $podman_latest_version https://github.com/containers/podman/ $shrooProjectDir/podman;
cd $shrooProjectDir/podman/;
make BUILDTAGS="systemd selinux seccomp" PREFIX=/usr;
sudo make install PREFIX=/usr;
podman version;

cd;
sudo rm -r $shrooProjectDir/podman;
[ ! -d /etc/containers/ ] && sudo mkdir /etc/containers 

sudo -u $shroober env XDG_RUNTIME_DIR=/run/user/$(id -u $shroober) bash -c "systemctl --user start podman.socket && systemctl --user status podman.socket && cd $shrooHome && podman run quay.io/podman/hello"
```

# Insecure Podman Repo

```bash
[ ! -f /etc/containers/policy.json ] && echo -e '{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ]
}
' | sudo tee -a /etc/containers/policy.json;

```

# Install Compose Plugin

```bash
docker_downs_url="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/"
needed_component="docker-compose-plugin"
# --no-check-certificate
echo "${docker_downs_url}$(curl -s $docker_downs_url | grep -oP "${needed_component}.*[.]deb"  | cut -d "\"" -f 1 | sort -V | tail -1)" | wget -O ${needed_component}.deb -i -
sudo dpkg -i "$needed_component.deb"
rm "$needed_component.deb"
```

# Setup Traefik

```bash
[ ! -d $shrooTraefikLogDir ] && sudo mkdir -p $shrooTraefikLogDir;
sudo touch $shrooTraefikLogDir/traefik.log;
sudo touch $shrooTraefikLogDir/access.log;

sudo mkdir -p $shrooTraefikDir/letsencrypt && sudo touch $shrooTraefikDir/letsencrypt/acme.json 
echo DOMAIN_NAME=$(hostname -d) | sudo tee -a $shrooTraefikDir/.traefik.env;
read -p 'Provider email: ' email && echo "PROVIDER_EMAIL=$email" | sudo tee -a $shrooTraefikDir/.traefik.env;
read -sp 'Provider API Token: ' token && echo "INFOMANIAK_ACCESS_TOKEN=$token" | sudo tee -a $shrooTraefikDir/.traefik.env;
sudo cp $shrooProjectDir/traefik/traefik.yml $shrooTraefikDir

sudo chown -R  $shroober:$shrooA $shrooTraefikLogDir $shrooTraefikDir && sudo chmod -R 0770 $shrooTraefikLogDir $shrooTraefikDir && sudo chmod 0600 $shrooTraefikDir/letsencrypt/acme.json;
```

# Setup Auth

```bash
sudo mkdir -p $shrooAuthDB $shrooAuthDir/media $shrooAuthDir/certs $shrooAuthDir/custom-templates;

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

sudo chown -R $shroober:$shrooA $shrooAuthDir $shrooAuthDB && sudo chmod -R 0770 $shrooAuthDir $shrooAuthDB
AUTHENTIK_BOOTSTRAP_TOKEN
```

# Setup Guac

```bash
sudo mkdir -p $shrooGuacDir/drive $shrooGuacDir/record $shrooGuacDB/init $shrooGuacDB/data

cd $shrooGuacDir;

echo "POSTGRES_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')" | sudo tee -a $shrooGuacDir/.guac-pg.env;
echo "POSTGRES_USER=guac_db_u" | sudo tee -a $shrooGuacDir/.guac-pg.env;
echo "POSTGRES_DB=guac_db" | sudo tee -a $shrooGuacDir/.guac-pg.env;
echo "PGDATA=/var/lib/postgresql/data/guacamole" | sudo tee -a $shrooGuacDir/.guac-pg.env;

echo "GUACD_HOSTNAME=guacd" | sudo tee -a $shrooGuacDir/.guac.env;
echo "POSTGRES_HOSTNAME=guac-pg" | sudo tee -a $shrooGuacDir/.guac.env;
sed -n '/^POSTGRES_USER/s/^POSTGRES_USER/POSTGRESQL_USER/p' $shrooGuacDir/.guac-pg.env | sudo tee -a $shrooGuacDir/.guac.env;
sed -n '/^POSTGRES_DB/s/^POSTGRES_DB/POSTGRESQL_DATABASE/p' $shrooGuacDir/.guac-pg.env | sudo tee -a $shrooGuacDir/.guac.env;
sed -n '/^POSTGRES_PASSWORD/s/^POSTGRES_PASSWORD/POSTGRESQL_PASSWORD/p' $shrooGuacDir/.guac-pg.env | sudo tee -a $shrooGuacDir/.guac.env;
echo "OPENID_AUTHORIZATION_ENDPOINT=https://auther.$(hostname -d):8443/application/o/authorize/" | sudo tee -a $shrooGuacDir/.guac.env;
echo "OPENID_JWKS_ENDPOINT=https://auther.$(hostname -d):8443/application/o/guac/jwks/" | sudo tee -a $shrooGuacDir/.guac.env;
echo "OPENID_ISSUER=https://auther.$(hostname -d):8443/application/o/guac/" | sudo tee -a $shrooGuacDir/.guac.env;
echo "OPENID_CLIENT_ID=Qif9JCKvGyb7FwToQEaCBGYfdcNgsSefD9WeoJXN" | sudo tee -a $shrooGuacDir/.guac.env;
echo "OPENID_REDIRECT_URI=https://guac.boredomndidit.com:8443" | sudo tee -a  $shrooGuacDir/.guac.env;

sudo chown -R $shroober:$shrooA $shrooGuacDir $shrooGuacDB && sudo chmod 0770 $shrooGuacDir $shrooGuacDB
```

# Fire in the Hole

```bash
sudo -u $shroober env XDG_RUNTIME_DIR=$shrooberXRD $(grep -v '^\s*#' $shrooProjectDir/res/exports/shrooVars | xargs) bash -c "cd $shrooProjectDir && podman compose up -d"
docker inspect <container_name_or_id> --format '{{.HostConfig.UsernsMode}}'
```

# Purge

```bash
> $HOME/.bash_exports
sudo rm -r  /var/lib/chimken /etc/traefik /etc/guac* /etc/auth* /var/log/traefik /var/lib/auth*DB
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
