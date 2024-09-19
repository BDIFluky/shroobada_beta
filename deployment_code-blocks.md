
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
palias "pps='podman ps'";
palias "pnls='podman network ls'";
palias "pvls='podman volume ls'";
palias "ppls='podman pod ls'";
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

# Setup Podman & Podlet
```bash
cd $PROJECT_DIR;
./script/setup_podman.sh -d -i -s -t -p
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
sudo cp -r -t /etc/ $PROJECT_DIR/traefik
touch traefik.log;
touch access.log;
sudo cp -r -t $TRAEFIK_LDIR access.log traefik.log;
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

# Steady
```bash
IFS=' ' read -r -a let_files <<< $(echo $(podlet -f $USER_SYSD --overwrite compose $PROJECT_DIR/compose.yml --pod) | sed "s|Wrote to file: ||g");
for lfile in ${let_files[@]};do
	echo $lfile
	if [[ "$lfile" == *".container" ]]; then
		sed -i 's/^Network=.*/&.network/' "$lfile"
	elif [[ "$lfile" == *".network" ]]; then
		echo "NetworkName=$(echo $lfile | sed 's/.*\/\([a-zA-Z\-_]*\)[.]network/\1/')" >> $lfile
	elif [[ "$lfile" == *".volume" ]]; then
		echo "VolumeName=$(echo $lfile | sed 's/.*\/\([a-zA-Z\-_]*\)[.]volume/\1/')" >> $lfile
	fi;
done;

sed -i 's/Network/#Network/g' $USER_SYSD/shroobada-traefik.container
echo "Network=TraefikNet.network" | tee -a $USER_SYSD/shroobada.pod

```

# Fire in the Hole
```bash
systemctl --user daemon-reload ;systemctl --user restart shroobada-pod;
```

# 
```bash

```
