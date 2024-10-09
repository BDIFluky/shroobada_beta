#!/bin/bash

TIMEOUT=3
echo -e "\e[33mThis gonna wipe the go workspace aswell you have $TIMEOUT seconds to abort.\e[0m"

read -t "$TIMEOUT" -n 1 -p "Press any key to abort" resp

[ -z "$char" ] && echo -e "\e[34mAborted\e[0m" && exit 0

sudo rm -r $GOPATH
sudo rm -r $GOROOT

echo -e "\e[34mGo uninstalled.\e[0m"
