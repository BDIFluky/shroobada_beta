#/bin/bash

# Print error and exits
error() {
  # Print the string in red
  echo -e "\e[31m$1\e[0m"
    
  # Exit the script
  exit 1
}

# Check if the script is being run as root
check_privileges() {
  if [ "$EUID" -ne 0 ]; then
    error "This script requires sudo privileges. Please run it as root or with sudo."
  fi
}

# Export project envs
setup_shroober(){
  id -u $shroober > /dev/null 2>&1 && sudo useradd -r -s /usr/sbin/nologin -d /var/lib/$shrooHPDir -m $shroober
  nextUID=$(awk -F: '{print $2 + $3}' "/etc/subuid" | sort -n | tail -n1)
  ! grep $shroober /etc/subuid && sudo usermod --add-subuids "$nextUID-$((nextUID + 65535))" "$shroober"
  
  nextGID=$(awk -F: '{print $2 + $3}' "/etc/subgid" | sort -n | tail -n1)
  ! grep $shroober /etc/subgid && sudo usermod --add-subgids "$nextGID-$((nextGID + 65535))" "$(sudo -u $shroober bash -c "id -g -n")"
  
  sudo loginctl enable-linger $shroober
}


add_repos(){
# Define the file paths
  REPO_FILE="/etc/apt/sources.list.d/added_repos.list"
  PREFERENCES_FILE="/etc/apt/preferences.d/main-priorities"
  
  # 1. Precheck for 'bookworm-backports' repository
  if ! grep -q "bookworm-backports" "$REPO_FILE"; then
      echo 'deb http://ftp.debian.org/debian bookworm-backports main contrib non-free' | sudo tee -a "$REPO_FILE"
  fi
  
  # 2. Precheck for 'trixie' repository
  if ! grep -q "trixie" "$REPO_FILE"; then
      echo 'deb http://ftp.debian.org/debian trixie main contrib non-free' | sudo tee -a "$REPO_FILE"
  fi
  
  # 3. Precheck for 'sid' repository
  if ! grep -q "sid" "$REPO_FILE"; then
      echo 'deb http://ftp.debian.org/debian sid main contrib non-free' | sudo tee -a "$REPO_FILE"
  fi
  
  # 4. Precheck for the APT preferences before appending
  if ! grep -q "Pin: release a=bookworm" "$PREFERENCES_FILE"; then
      sudo tee -a "$PREFERENCES_FILE" <<EOF
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
  fi

}


shrooA="$(whoami)"
shrooProjectDir="$HOME/shroobada"
shroober="chimken"
shrooberUID="$(id -u $shroober)"
shrooberGID="$(id -g $shroober)"
shrooHPDir="/var/lib/$shroober"
shrooCPDir="$shrooHPDir/shroobada"
shrooProjectDir="$shrooHPDir/shroobada"

shrooRPDir="/etc/traefik"
shrooRPLogDir="/var/log/traefik"

shrooAuthDir="/etc/authentik"
shrooAuthDB="/var/lib/authdb"

shrooGuacDir="/etc/guacamole"
shrooGuacDB="/var/lib/guacdb"

check_privileges()

setup_shroober()
add_repos()


