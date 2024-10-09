#!/bin/bash

# setting script vars
SGOPATH="${GOPATH:-$HOME/go}"
SGOROOT="${GOROOT:-/opt/}"
read_timeout=3

# Function to ask if the user wants to change the variable
keep_or_change_env() {
    local var_value 
    var_value= $(eval "echo \$$1")
    echo -e "\e[34m$1\e[0m=\e[33m'${var_value}'\e[0m"
    
    # Loop until the user provides a valid response
    while true; do
        read -t "$read_timeout" -p "Do you want to keep this value? (y/n) [Timeout in $read_timeout seconds]: " response
        response="${response:-y}"  # Default to 'y' if no input within timeout

        # Check for valid response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            break
        elif [[ "$response" =~ ^[Nn]$ ]]; then
            read -p "Enter new value for $1: " new_value
            eval "$1='\"$new_value\"'"
            break
        else
            echo -e "\e[31mInvalid input. Please enter 'y' or 'n'.\e[0m"
        fi
    done
}

fetch_and_install_go() {
  local go_latest_version
  go_latest_version=$(curl -s https://go.dev/dl/ | grep -oP 'go[0-9]+\.[0-9]+(\.[0-9]+)?\.linux-amd64\.tar\.gz' | head -n 1)
  wget -q https://go.dev/dl/$go_latest_version
  sudo tar -C $SGOROOT -xzf $go_latest_version
  [[ ":$PATH:" == *":$SGOROOT/go/bin:"* ]] && echo "export PATH=\$PATH:$SGOROOT/go/bin" >> ~/.bashrc;
  source ~/.bashrc;
  go env -w GOPATH="$SGOPATH"
  [ ! -d $SGOPATH ] && mkdir -p $SGOPATH
  rm go_latest_version
}

keep_or_change_env SGOPATH
keep_or_change_env SGOROOT

fetch_and_install_go
