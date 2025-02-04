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

sudo -u $shroober env XDG_RUNTIME_DIR=/run/user/$(id -u $shroober) bash -c "systemctl --user start podman.socket && systemctl --user status podman.socket && cd \$HOME && podman run quay.io/podman/hello"
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

# Test Podman
```bash
#systemctl --user start podman.socket;
#systemctl --user enable podman.socket;
#systemctl --user status podman.socket;

#podman run quay.io/podman/hello
```
