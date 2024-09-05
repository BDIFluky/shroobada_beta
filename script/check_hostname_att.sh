#!/bin/bash

function apply_changes {
  local HOSTNAME=$1
  local DOMAIN_NAME=$2
  local IP=$3

  echo -e "Setting domain name to \e[33m$DOMAIN_NAME\e[0m..."
  
  sudo sed -i "s/127.0.1.1.*/$IP\t$HOSTNAME\t$HOSTNAME.$DOMAIN_NAME/" /etc/hosts
  
  echo -e "\e[32mDomain name updated to \e[33m$DOMAIN_NAME\e[0m"
  
  echo -e "Setting hostname to \e[33m$HOSTNAME\e[0m..."
  
  # Set the hostname immediately
  sudo hostnamectl set-hostname "$HOSTNAME"
  
  # Ensure the hostname is persistent across reboots
  echo "$HOSTNAME" | sudo tee /etc/hostname > /dev/null
  
  echo -e "\e[32mHostname updated to \e[33m$HOSTNAME\e[0m"

  echo -e "\e[32mOutput of hostname -d :\e[33m$(hostname -d)\e[0m"
  
  echo -e "\e[32mOutput of hostname -f :\e[33m$(hostname -f)\e[0m"

}

# Get the current hostname
CURRENT_HOSTNAME=$(hostname)

echo -e "The current hostname is: \e[33m$CURRENT_HOSTNAME\e[0m"
read -p "Do you want to keep this hostname? (Y/n): " RESPONSE

if [[ "$RESPONSE" == "n" ]]; then
    read -p "Enter the new hostname: " NEW
    CURRENT_HOSTNAME=$NEW
else
    echo -e "\e[34mNo changes made to the hostname.\e[0m"
fi

# Get the current domain name
CURRENT_DOMAIN_NAME=$(hostname -d)

echo -e "The current domain name is: \e[33m$CURRENT_DOMAIN_NAME\e[0m"
read -p "Do you want to keep this domain name? (Y/n): " RESPONSE

if [[ "$RESPONSE" == "n" ]]; then
    read -p "Enter the new domain name: " NEW
    CURRENT_DOMAIN_NAME=$NEW
    
    mapfile -t int_array < <(ip -4 -o a | grep -v -e '127.0.0.1' -e '::1/128' | awk '
      {
          ip = $4;
          if ($9 ~ ($2 ".*")) {
              split($9, arr, "\\");
              
          } else if ($10 ~ ($2 ".*")) {
              split($10, arr, "\\");
          } else {
              split($11, arr, "\\");
          }
          print "\033[34m" arr[1] "\033[0m > " ip;
      }')

    PS3="Select the interface for domain/host association: "
    select int in "${int_array[@]}"; do
        if [[ -n "$int" ]]; then
            IP=$(echo $int | awk '{print $3}' | cut -d'/' -f1)
            break
        else
            echo -e "\e[91mInvalid selection. Please try again.\e[0m"
        fi
    done
    
else
    echo -e "\e[34mNo changes made to the domain name.\e[0m"
fi

apply_changes "$CURRENT_HOSTNAME" "$CURRENT_DOMAIN_NAME" "$IP"

