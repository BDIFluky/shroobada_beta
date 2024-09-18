#!/bin/bash

# Check if arguments are provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 -d -i -s -t -p"
    echo "At least one argument is required"
    exit 1
fi

while [[ "$1" != "" ]]; do
    case $1 in
        -d)
            echo "downloading dependencies..."
            sudo DEBIAN_FRONTEND=noninteractive apt install -y \
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
              conmon
            ;;
            
        -i)
            echo "Retrieving & installing Podman latest version..."
            podman_latest_version=$(curl -ks https://api.github.com/repos/containers/podman/releases/latest | awk '/tag_name/ {print $2}' | sed -r 's/"|,//g');
            cd;
            #-c http.sslVerify=false
            git clone -b $podman_latest_version https://github.com/containers/podman/;
            cd podman/;
            make BUILDTAGS="systemd selinux seccomp" PREFIX=/usr;
            sudo make install PREFIX=/usr;
            podman version;
            cd;
            sudo rm -r podman;
            ;;
            
        -s)
            echo "setting up Podman..."
            [ ! -d /etc/containers/ ] && sudo mkdir /etc/containers 
            [ ! -d $HOME/.config/containers/systemd/ ] && mkdir -p $HOME/.config/containers/systemd/;
            systemctl --user start podman.socket;
            systemctl --user enable podman.socket;
            ;;
            
        -t)
            echo "Podman test"
            systemctl --user status podman.socket;
            podman run quay.io/podman/hello
            ;;
            
        -p)
            echo "Retrieving and installing Podlet"
            # --no-check-certificate
            curl -ks https://api.github.com/repos/containers/podlet/releases/latest | awk '/browser_download_url.*x86_64.*-linux-gnu.*tar.xz"$/ {print $2}'| sed -r 's/"//g'|wget -i -;
            tar -xf podlet-x86_64-unknown-linux-gnu.tar.xz;
            sudo cp podlet-x86_64-unknown-linux-gnu/podlet /usr/bin/;
            podlet -V;
            rm -r podlet*
            ;;
    esac
    shift
done
