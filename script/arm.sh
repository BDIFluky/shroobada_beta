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

# Install required packages
install_required_packages() {
    local required=('jq' 'git')
    local missing=""

    for pack in "${required[@]}"; do dpkg -l | grep -qw $pack || missing+="$pack "; done

    # Install missing packages
    [ -n "$missing" ] && sudo apt install -y $missing
}

# Clone project & enable scripts
clone_shroobada() {
  shrooProjectDir=~/shroobada;
  # -c http.sslVerify=false
  git clone https://github.com/BDIFluky/shroobada $shrooProjectDir;
  
  chmod +x $shrooProjectDir/script/*.sh;
  #chmod +x $shrooProjectDir/fire_in_the_hole.sh;
}

# Export project envs
export_project_envs(){
  export $(grep -v '^#' .shroo.env | xargs)
}

check_privileges()
check_required_packages()
