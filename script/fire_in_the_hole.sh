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
export_project_envs(){
  export $(grep -v '^#' .shroo.env | xargs)
}

check_privileges()

export_project_envs()
