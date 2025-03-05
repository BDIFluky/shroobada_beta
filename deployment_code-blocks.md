# Fetch Repo

```bash
shroober=chimken
shrooberHome=$(eval echo ~$shroober)
# -c http.sslVerify=false
sudo git clone https://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@github.com/BDIFluky/shroobada_beta $shrooberHome/shrooTemp
sudo chown -R $shroober $shrooberHome/shrooTemp
sudo cp -rp $shrooberHome/shrooTemp/* $shrooberHome
sudo rm -r $shrooberHome/shrooTemp
```

# shrooVars
```bash
shrooVarsPath=$shrooberHome/shrooVars
sudo tee $shrooVarsPath > /dev/null <<EOF
shroober=chimken
shrooberHome=\$(eval echo ~\$shroober)
shrooberXRD=/run/user/\$(id -u \$shroober)
shrooVarsPath=\$shrooberHome/shrooVars
shrooServicesPath=\$shrooberHome/services
shrooTraefikName=traefik
shrooTraefikDir=/etc/traefik
shrooCMSocket=\$shrooberXRD/podman/podman.sock
shrooAuthName=auth
shrooAuthDir=/etc/authentik
shrooGuacName=guac
shrooGuacDir=/etc/guacamole
shrooGuacDB=/var/lib/guacamole
EOF
```

# Parse shrooVars

```bash
shrooVarsPath=$shrooberHome/shrooVars

temp=$(mktemp) && grep -v "^#" "$shrooVarsPath" | xargs -d "\n" -I{} echo export {} > $temp && . $temp
[[ -f $temp ]] && rm $temp
```

# Shrooberdo (Start and Enable Podman Socket)
```bash
sudo loginctl enable-linger $shroober
sudo -u $shroober env XDG_RUNTIME_DIR=/run/user/$(id -u $shroober) bash -c "systemctl --user start podman.socket && systemctl --user enable podman.socket && systemctl --user status podman.socket" 
```

# Setup Traefik

```bash
sudo mkdir -p $shrooTraefikDir/letsencrypt && sudo touch $shrooTraefikDir/letsencrypt/acme.json 
echo DOMAIN_NAME=$(hostname -d) | sudo tee -a $shrooTraefikDir/.traefik.env;
sudo cp -rp $shrooberHome/services/traefik/* $shrooTraefikDir
sudo chown -R $shroober $shrooTraefikDir
sudo chmod 0600 $shrooTraefikDir/letsencrypt/acme.json;

read -p 'Provider email: ' email && echo "PROVIDER_EMAIL=$email" | sudo tee -a $shrooTraefikDir/.traefik.env;
read -sp 'Provider API Token: ' token && echo "INFOMANIAK_ACCESS_TOKEN=$token" | sudo tee -a $shrooTraefikDir/.traefik.env;
sudo cp $shrooProjectDir/traefik/traefik.yml $shrooTraefikDir

sudo chown -R  $shroober:$shrooA $shrooTraefikLogVol $shrooTraefikDir && sudo chmod -R 0770 $shrooTraefikLogVol $shrooTraefikDir && sudo chmod 0600 $shrooTraefikDir/letsencrypt/acme.json;
```

```bash
yq -i -y "del(.services.\"${SERVICE_NAME}\".ports)" "$COMPOSE_FILE"
```

# Setup Auth

```bash
sudo mkdir -p $shrooAuthDir/media;

echo "POSTGRES_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')" | sudo tee -a $shrooAuthDir/.auth-pg.env;
echo "POSTGRES_USER=auth_db_u" | sudo tee -a $shrooAuthDir/.auth-pg.env;
echo "POSTGRES_DB=auth_db" | sudo tee -a $shrooAuthDir/.auth-pg.env;

echo "AUTHENTIK_REDIS__HOST=auth-redis" | sudo tee -a $shrooAuthDir/.auth.env;
echo "AUTHENTIK_POSTGRESQL__HOST=auth-pg" | sudo tee -a $shrooAuthDir/.auth.env;
sudo sed -n '/^POSTGRES_USER/s/^POSTGRES_USER/AUTHENTIK_POSTGRESQL__USER/p' $shrooAuthDir/.auth-pg.env | sudo tee -a $shrooAuthDir/.auth.env;
sudo sed -n '/^POSTGRES_DB/s/^POSTGRES_DB/AUTHENTIK_POSTGRESQL__NAME/p' $shrooAuthDir/.auth-pg.env | sudo tee -a $shrooAuthDir/.auth.env;
sudo sed -n '/^POSTGRES_PASSWORD/s/^POSTGRES_PASSWORD/AUTHENTIK_POSTGRESQL__PASSWORD/p' $shrooAuthDir/.auth-pg.env | sudo tee -a $shrooAuthDir/.auth.env;
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')" | sudo tee -a $shrooAuthDir/.auth.env;
echo "AUTHENTIK_BOOTSTRAP_PASSWORD=Chang3M3n0w" | sudo tee -a $shrooAuthDir/.auth.env;
echo "AUTHENTIK_BOOTSTRAP_TOKEN=Chang3M3n0w" | sudo tee -a $shrooAuthDir/.auth.env;
echo "AUTHENTIK_ERROR_REPORTING__ENABLED=false" | sudo tee -a $shrooAuthDir/.auth.env;

sudo chown -R $shroober $shrooAuthDir && sudo chmod -R 0700 $shrooAuthDir && sudo find $shrooAuthDir -type f -exec chmod 0600 {} \;
```

# Setup Guac

```bash
sudo mkdir -p $shrooGuacDir/drive $shrooGuacDir/record $shrooGuacDB/init $shrooGuacDB/data

cd $shrooGuacDir;

podman run --rm docker.io/guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql | sudo tee $shrooGuacDB/init/initdb.sql

echo "POSTGRES_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')" | sudo tee -a $shrooGuacDir/.guac-pg.env;
echo "POSTGRES_USER=guac_db_u" | sudo tee -a $shrooGuacDir/.guac-pg.env;
echo "POSTGRES_DB=guac_db" | sudo tee -a $shrooGuacDir/.guac-pg.env;
echo "PGDATA=/var/lib/postgresql/data/guacamole" | sudo tee -a $shrooGuacDir/.guac-pg.env;

echo "GUACD_HOSTNAME=guacd" | sudo tee -a $shrooGuacDir/.guac.env;
echo "POSTGRES_HOSTNAME=guac-pg" | sudo tee -a $shrooGuacDir/.guac.env;
sed -n '/^POSTGRES_USER/s/^POSTGRES_USER/POSTGRESQL_USER/p' $shrooGuacDir/.guac-pg.env | sudo tee -a $shrooGuacDir/.guac.env;
sed -n '/^POSTGRES_DB/s/^POSTGRES_DB/POSTGRESQL_DATABASE/p' $shrooGuacDir/.guac-pg.env | sudo tee -a $shrooGuacDir/.guac.env;
sed -n '/^POSTGRESQL_PASSWORD/s/^POSTGRES_PASSWORD/POSTGRESQL_PASSWORD/p' $shrooGuacDir/.guac-pg.env | sudo tee -a $shrooGuacDir/.guac.env;
echo "GUACAMOLE_HOME=/etc/guacamole/.guacamole" | sudo tee -a $shrooGuacDir/.guac.env;
echo "EXTENSION_PRIORITY= postgresql,openid" | sudo tee -a $shrooGuacDir/.guac.env;
echo "REMOTE_IP_VALVE_ENABLED=true" | sudo tee -a $shrooGuacDir/.guac.env;
echo "POSTGRESQL_AUTO_CREATE_ACCOUNTS=true" | sudo tee -a $shrooGuacDir/.guac.env;
echo "OPENID_AUTHORIZATION_ENDPOINT=https://auth.$(hostname -d)/application/o/authorize/" | sudo tee -a $shrooGuacDir/.guac.env;
echo "OPENID_JWKS_ENDPOINT=http://auth:9000/application/o/guac/jwks/" | sudo tee -a $shrooGuacDir/.guac.env;
echo "OPENID_ISSUER=https://auth.$(hostname -d)/application/o/guac/" | sudo tee -a $shrooGuacDir/.guac.env;
echo "OPENID_CLIENT_ID=[ID]" | sudo tee -a $shrooGuacDir/.guac.env;
echo "OPENID_REDIRECT_URI=https://guac.$(hostname -d)" | sudo tee -a  $shrooGuacDir/.guac.env;
echo "enable-environment-properties: true" | sudo tee $shrooGuacDir/guacamole-home/guacamole.properties

sudo chown -R $shroober $shrooGuacDir $shrooGuacDB && sudo chmod 0770 $shrooGuacDir $shrooGuacDB

podman exec -it guac find /opt/guacamole/openid/ -name '*.jar' -exec ln -s {} /home/guacamole/.guacamole/extensions/ \;

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
podman run --rm docker.io/guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > initdb.sql
sed -i -e 's/guacadmin/fluky/' -e '/decode/d' initdb.sql

```
# Setup NAT
```bash
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
```
# 

```bash

```


