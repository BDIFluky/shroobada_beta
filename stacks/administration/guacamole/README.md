<p align="center">
<img height="150" title="Guacamole" src="guacamole.logo.svg" alt="">
</p>

---

Guacamole is a clientless remote desktop gateway developed by `Apache`. It supports standard protocols like VNC, RDP, and SSH. This guide covers how to setup Guacamole using containerization and how to integrate it with Traefik and authentik.

## Table of Content

- [Compose File](#compose-file)

## Compose File

## Script

```bash
# get token
baseUrl="http://localhost:8080/"
endPoint="api/tokens"

authToken=$(curl -s -X POST -G -d 'username=guacadmin&password=guacadmin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/json' "$baseUrl$endPoint")
authToken=$(echo $authToken | jq '.authToken' | tr -d '"')

# change password
endPoint="api/session/data/postgresql/users/guacadmin/password"

password=$(openssl rand -base64 32)

user=$(curl -s -X PUT -H "Guacamole-Token: $authToken" -H 'Content-Type: application-json' -H 'Accept: application/json' "$baseUrl$endPoint" -d "{ \"oldPassword\": \"guacadmin\", \"newPassword\": \"$password\"}")

# delete token
endPoint="api/tokens/$authToken"

authToken=$(curl -s -X DELETE -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/json' "$baseUrl$endPoint")
authToken=$(echo $authToken | jq '.authToken' | tr -d '"')
```