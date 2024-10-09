#!/bin/bash

# setting script vars
SGOPATH="${GOPATH:-$HOME/go}"
SGOROOT="${GOROOT:-/opt/}"
READ_TIMEOUT=3


fetch_and_install_go() {
  local go_latest_version
  go_latest_version=$(curl -s https://go.dev/dl/ | grep -oP 'go[0-9]+\.[0-9]+(\.[0-9]+)?\.linux-amd64\.tar\.gz' | head -n 1)
  wget -q https://go.dev/dl/$go_latest_version
  sudo tar -C $SGOROOT -xzf $go_latest_version
  [[ ":$PATH:" == *":$SGOROOT/go/bin:"* ]] && echo "export PATH=\$PATH:$SGOROOT/go/bin" >> ~/.bashrc;
  source ~/.bashrc;
  go env -w GOPATH="$SGOPATH"
  [ ! -d $SGOPATH ] && mkdir -p $SGOPATH
  rm $go_latest_version

  go version && echo -e "\e[34mGo installed successfully.\e[0m"
}

keep_or_change_env SGOPATH
keep_or_change_env SGOROOT

fetch_and_install_go
