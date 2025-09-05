# /bin/bash

# Create New Superuser
baseUrl="$1/api/v3/"
endpoint="core/users/"
requestUrl="$baseUrl$endpoint"

AUTHENTIK_BOOTSTRAP_TOKEN=$2

userName="fluky"
name="Fluky Morningstar"
userType="internal"
dataSet="{
  \"username\": \"$userName\",
  \"name\": \"$name\",
  \"is_active\": true,
  \"type\": \"$userType\"
}"

newUser=$(curl -s -X POST -L "$requestUrl"\
              -H 'Content-Type: application/json'\
              -H 'Accept: application/json'\
              -H "Authorization: Bearer $AUTHENTIK_BOOTSTRAP_TOKEN"\
              --data-raw "$dataSet ")\
&& echo -e "\e[32mNew User created:\e[0m\n$(echo $newUser | jq -C)"\
|| echo -e "\e[31mUser Creation failed:\e[0m\n$(echo $newUser | jq -C)"

# Set a Password for the New User
endpoint="core/users/$(echo $newUser | jq '.pk')/set_password/"
requestUrl="$baseUrl$endpoint"

newPassword="$(openssl rand -base64 32)"
dataSet="{
  \"password\": \"$newPassword\"
}"

curl -s -X POST -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $AUTHENTIK_BOOTSTRAP_TOKEN"\
      -d "$dataSet"\
&& echo -e "\e[32m$(echo $newUser | jq '.username' | tr -d '"')'s new password: \e[34m$newPassword\e[0m"\
|| echo -e "\e[31m$(echo $newUser | jq '.username' | tr -d '"')'s new password creation failed: \e[33m$(echo $newPassword | jq -C)\e[0m"

# Add the New User to an Admin Group
endpoint="core/groups/"
requestUrl="$baseUrl$endpoint"

adminGroupUUID=$(curl -s -X GET -L "$requestUrl"\
                      -H 'Accept: application/json'\
                      -H "Authorization: Bearer $AUTHENTIK_BOOTSTRAP_TOKEN"\
                  | jq '.results[] | select(.name=="authentik Admins").pk')

endpoint="core/groups/$(echo $adminGroupUUID | tr -d '"')/add_user/"
requestUrl="$baseUrl$endpoint"

dataSet="{
  \"pk\": $(echo $newUser | jq '.pk')
}"

curl -s -X POST -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $AUTHENTIK_BOOTSTRAP_TOKEN"\
      -d "$dataSet"\
&& echo -e "\e[32m$(echo $newUser | jq '.username' | tr -d '"') has been added to authentik Admins.\e[0m"\
|| echo -e "\e[31mFailed to add $(echo $newUser | jq '.username' | tr -d '"') to authentik Admins.\e[0m"

# Create a New API Token Linked to the New User
endpoint="core/tokens/"
requestUrl="$baseUrl$endpoint"

dataSet="{
  \"identifier\": \"$(echo $newUser | jq '.username' | tr -d '"')-api-token\",
  \"intent\": \"api\",
  \"user\": \"$(echo $newUser | jq '.pk')\",
  \"expiring\": false
}"

newToken=$(curl -s -X POST -L "$requestUrl"\
                -H 'Content-Type: application/json'\
                -H 'Accept: application/json'\
                -H "Authorization: Bearer $AUTHENTIK_BOOTSTRAP_TOKEN"\
                -d "$dataSet")\
&& echo -e "\e[32m$(echo $newUser | jq '.username' | tr -d '"')'s new API Token:\e[0m\n$(echo $newToken |jq -C)"\
|| echo -e "\e[31mFailed to create $(echo $newUser | jq '.username' | tr -d '"')'s new API Token:\e[0m\n$(echo $newToken |jq -C)"

endpoint="core/tokens/$(echo $newToken | jq '.identifier' | tr -d '"')/set_key/"
requestUrl="$baseUrl$endpoint"

newKey="$(openssl rand -base64 32)"
dataSet="{
  \"key\": \"$newKey\"

}"

curl -s -X POST -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $AUTHENTIK_BOOTSTRAP_TOKEN"\
      -d "$dataSet"\
&& echo -e "\e[32m$(echo $newToken | jq '.identifier' | tr -d '"')'s key: \e[34m$newKey\e[0m"\
|| echo -e "\e[31mFailed to create $(echo $newToken | jq '.identifier' | tr -d '"')'s key: \e[33m$(echo $newKey | jq -C)\e[0m"

# Delete AUTHENTIK_BOOTSTRAP_TOKEN
endpoint="core/tokens/authentik-bootstrap-token/"
requestUrl="$baseUrl$endpoint"

dataSet="{
  \"pk\": $(echo $newUser | jq '.pk')
}"

curl -s -X DELETE -L "$requestUrl"\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $AUTHENTIK_BOOTSTRAP_TOKEN"\
&& echo -e "\e[32mAUTHENTIK_BOOTSTRAP_TOKEN has been deleted.\e[0m"\
|| echo -e "\e[31mFailed to delete AUTHENTIK_BOOTSTRAP_TOKEN.\e[0m"

# Set a Password for akadmin and Deactivate It
endpoint="core/users/"
requestUrl="$baseUrl$endpoint"

akadminUID=$(curl -s -X GET -L "$requestUrl"\
              -H 'Accept: application/json'\
              -H "Authorization: Bearer $newKey" | jq '.results[] | select(.username=="akadmin").pk')

endpoint="core/users/$akadminUID/set_password/"
requestUrl="$baseUrl$endpoint"

newPassword=$(openssl rand -base64 32)
dataSet="{
  \"password\": \"$newPassword\"
}"

curl -s -X POST -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $newKey" -d "$dataSet"\
&& echo -e "\e[32makadmin's new password: \e[34m$newPassword\e[0m"\
|| echo -e "\e[31mFailed to set akadmin's new password: \e[33m$(echo $newPassword | jq -C)\e[0m"

endpoint="core/users/$akadminUID/"
requestUrl="$baseUrl$endpoint"

dataSet="{
  \"is_active\": false
}"

curl -s -X PATCH -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $newKey" -d "$dataSet" > /dev/null\
&& echo -e "\e[32makadmin has been deactivated.\e[0m"\
|| echo -e "\e[31Failed to deactivate akadmin.\e[0m"

# Create new user
endpoint="core/users/"
requestUrl="$baseUrl$endpoint"
userName="chimken"
name="Chimken Nughers"
userType="internal"
dataSet="{
  \"username\": \"$userName\",
  \"name\": \"$name\",
  \"is_active\": true,
  \"type\": \"$userType\"
}"

newUser=$(curl -s -X POST -L "$requestUrl"\
              -H 'Content-Type: application/json'\
              -H 'Accept: application/json'\
              -H "Authorization: Bearer $newKey"\
              --data-raw "$dataSet ")\
&& echo -e "\e[32mNew User created:\e[0m\n$(echo $newUser | jq -C)"\
|| echo -e "\e[31mUser Creation failed:\e[0m\n$(echo $newUser | jq -C)"

# Set a Password for the New User
endpoint="core/users/$(echo $newUser | jq '.pk')/set_password/"
requestUrl="$baseUrl$endpoint"

newPassword="$(openssl rand -base64 32)"
dataSet="{
  \"password\": \"$newPassword\"
}"

curl -s -X POST -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $newKey"\
      -d "$dataSet"\
&& echo -e "\e[32m$(echo $newUser | jq '.username' | tr -d '"')'s new password: \e[34m$newPassword\e[0m"\
|| echo -e "\e[31m$(echo $newUser | jq '.username' | tr -d '"')'s new password creation failed: \e[33m$(echo $newPassword | jq -C)\e[0m"
