<p align="center">
<img height="150" title="Authentik" src="/docs/assets/img/authentik.logo.svg" alt="">
</p>

---

authentik is a robust Identity Provider (IdP) and Single Sign-On (SSO) solution that prioritizes security, flexibility, and versatility. This guide demonstrates how to leverage authentik to centralize authentication and seamlessly enable SSO across multiple services, simplifying user management and strengthening overall security.

## Table of Content

- [Compose File](#compose-file)
- [Traefik Integration](#traefik-integration)
  - [Authentication Middleware](#authentication-middleware)
- [First Startup](#first-startup)
  - [Create a New Superuser](#create-a-new-superuser)
  - [Set a Password for the New User](#set-a-password-for-the-new-user)
  - [Add the New User to an Admin Group](#add-the-new-user-to-an-admin-group)
  - [Create a New API Token Linked to the New User](#create-a-new-api-token-linked-to-the-new-user)
  - [Delete AUTHENTIK_BOOTSTRAP_TOKEN](#delete-authentik_bootstrap_token)
  - [Set a Password for akadmin and Deactivate It](#set-a-password-for-akadmin-and-deactivate-it)
  - [Comprehensive Script](#comprehensive-script)
- [Service Integration](#service-integration)

## Compose File

The compose file for authentik is located at [`authentik-compose.yml`](/services/authentik/authentik-compose.yml). It’s a modified version of [authentik's official compose file](https://docs.goauthentik.io/docs/install-config/install/docker-compose) and can be customized through various environment variables:

- **shrooAuthName:** Specifies a container name for the server service and a prefix for the other services. For usage purpose, see the [Default Rule for Exposed Containers](default-rule-for-exposed-containers).
- **shrooAuthDir:** Defines the absolute path where authentik’s files are stored locally.
- **shrooAuthDB:** Defines the absolute path where authentik's database is stored locally.

The `.auth.env` file is passed to both the auth-server and auth-worker services. It contains the required environment variables for this guide:

- **AUTHENTIK_REDIS__HOST:** Redis server host when not using configuration URL, as we change the redis' container name this should be set to `auth-redis`.
- **AUTHENTIK_POSTGRESQL__HOST:** Hostname of your PostgreSQL Server (`auth-pg`).
- **AUTHENTIK_POSTGRESQL__USER:** Database user.
- **AUTHENTIK_POSTGRESQL__NAME:** Database name.
- **AUTHENTIK_POSTGRESQL__PASSWORD:** Database password, defaults to the environment variable `POSTGRES_PASSWORD`.
- **AUTHENTIK_SECRET_KEY:** Secret key used for cookie signing. Changing this will invalidate active sessions.
- **AUTHENTIK_BOOTSTRAP_PASSWORD:** Configure the default password for the akadmin user. Only read on the first startup. Can be used for any flow executor. See [Automated install | authentik](https://docs.goauthentik.io/docs/install-config/automated-install).
- **AUTHENTIK_BOOTSTRAP_TOKEN:** Create a token for the default akadmin user. Only read on the first startup. The string you specify for this variable is the token key you can use to authenticate yourself to the API. See [Automated install | authentik](https://docs.goauthentik.io/docs/install-config/automated-install).
- **AUTHENTIK_ERROR_REPORTING__ENABLED:** Enable error reporting. Defaults to false.

> [!NOTE]
> For a list of recognized environment variables, see the [Configuration | authentik](https://docs.goauthentik.io/docs/install-config/configuration/) and [Automated install | authentik](https://docs.goauthentik.io/docs/install-config/automated-install).

The `.auth-pg.env` file is passed to the PostgreSQL container to configure authentik's database, it includes:

- **POSTGRES_PASSWORD:** Database password.
- **POSTGRES_USER:** Database user.
- **POSTGRES_DB:** Database name.

Two networks—`AuthFrontNet` and `AuthBackNet`—are defined to separate front-end and back-end communications. Only the front-end is externally accessible.

> [!NOTE]
> Only `/media` is mounted in `auth-server` and `auth-worker`, this mount point is optional and is used to store icons and such, but not required, and if not mounted, authentik will allow you to set a URL to icons in place of a file upload.
> Other optional mount points are :
> - `/certs` is used for authentik to import external certs, which in most cases shouldn't be used for SAML, but rather if you use authentik without a reverse proxy, this is used for the lets encrypt integration.
> - `/templates` is used for custom email templates, and as with the other ones fully optional.

## Traefik Integration

authentik’s web interface can be made accessible through Traefik by exposing the `auth-server` service via the container manager’s socket and enabling network communication between the Traefik and authentik server. The relevant steps are:

- **Adding labels & Expose port :**

```yml
  auth-server:
    expose:
      - "9000" # Exposes port `9000` as no port is exposed on the DOCKERFILE, port 9443 is omitted out because Traefik handles TLS automatically.
    labels:
      - "traefik.enable=true" # exposes the web interface to Traefik
      - "traefik.docker.network=AuthFrontNet" # Instructs Traefik to use AuthFrontNet for communication with `auth-server`
```

- **Attaching Traefik to authentik’s Front-End Network:**

```yml
  traefik:
    networks:
      - AuthFrontNet
```

> [!NOTE]
> It's possible to remove or comment out the port bindings in [`authentik-compose.yml`](/services/authentik/authentik-compose.yml#L11-L13)

### Authentication Middleware

Traefik can forward authentication requests to authentik by referencing a custom middleware configuration. For details, see  [`auther-mwr.yml`](/services/authentik/auth-mwr.yml).

## First Startup

Automated initialization can be performed by creating a new superuser, generating an API token, assigning a password and then deactivating the default `akadmin` user. This process relies on the `AUTHENTIK_BOOTSTRAP_TOKEN` environment variable for API access.

> [!NOTE]
> A [comprehensive script](#comprehensive-script) is also available, consolidating all the snippets presented in this section for easier deployment.<br>
> The scripts in this section use `curl` and `jq` to send request and parse JSON data.

For demonstration purposes, these examples assume that the authentik web interface is accessible at localhost:9000.

### Create a New Superuser

The following snippet, demonstrates the use of [core_users_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-users-create) to create a user named `fluky`. the JSON response is stored in the `newUser` variable:
```shell
baseUrl="localhost:9000/api/v3/"
endpoint="core/users/"
requestUrl="$baseUrl$endpoint"

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
              --data-raw "$dataSet ")
```

### Set a Password for the New User

The next snippet uses [core_users_set_password_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-users-set-password-create) to set a password for `fluky`:
> [!NOTE]
> 1. The endpoint for setting a user’s password follows the pattern `core/users/:id/set_password/` where `:id` is the user’s pk.
> 2. The generated password should be stored securely; it cannot be retrieved later. (although the account can be recovered).
```shell
baseUrl="localhost:9000/api/v3/"
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
      -d "$dataSet"
```

### Add the New User to an Admin Group

In the following snippet the [core_groups_list | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-groups-list) endpoint is called to retrieve `authentik Admins` UUID. Then the [core_groups_add_user_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-groups-add-user-create) endpoint is invoked to add `fluky` to that group:
```shell
baseUrl="localhost:9000/api/v3/"
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
      -d "$dataSet"
```

### Create a New API Token Linked to the New User

The [core_tokens_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-tokens-create) endpoint creates a new token for `fluky`, and the [core_tokens_set_key_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-tokens-set-key-create) endpoint sets its key:
> [!NOTE]
> This key should be kept securely; there is no method to retrieve it at a later time.
```shell
baseUrl="localhost:9000/api/v3/"
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
                -d "$dataSet")

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
      -d "$dataSet"
```

### Delete AUTHENTIK_BOOTSTRAP_TOKEN
The following snippet uses [core_tokens_destroy | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-tokens-destroy) to delete `AUTHENTIK_BOOTSTRAP_TOKEN`:
```shell
baseUrl="localhost:9000/api/v3/"

endpoint="core/tokens/authentik-bootstrap-token/"
requestUrl="$baseUrl$endpoint"

dataSet="{
  \"pk\": $(echo $newUser | jq '.pk')
}"

curl -s -X DELETE -L "$requestUrl"\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $AUTHENTIK_BOOTSTRAP_TOKEN"
```

### Set a Password for akadmin and Deactivate It
The [core_users_list | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-users-list) endpoint locates the `akadmin` user by username, [core_users_set_password_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-users-set-password-create) assigns a new password, and [core_users_partial_update | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-users-partial-update) deactivates the account:
> [!NOTE]
> 1. The endpoint for setting a user’s password follows the pattern `core/users/:id/set_password/` where `:id` is the user’s pk.
> 2. The generated password should be stored securely; it cannot be retrieved later. (although the account can be recovered).
```shell
baseUrl="localhost:9000/api/v3/"
endpoint="core/users/"
requestUrl="$baseUrl$endpoint"

akadminUID=$(curl -s -X GET -L "$requestUrl"\
              -H 'Accept: application/json'\
              -H "Authorization: Bearer $newKey" | jq '.results[] | select(.username=="akadmin").pk')
              
endpoint="core/users/$akadminUID/set_password/"
requestUrl="$baseUrl$endpoint"

dataSet="{
  \"password\": \"$(openssl rand -base64 32)\"
}"

curl -s -X POST -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $newKey" -d "$dataSet"

endpoint="core/users/$akadminUID/"
requestUrl="$baseUrl$endpoint"

dataSet="{
  \"is_active\": false
}"

curl -s -X PATCH -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $newKey" -d "$dataSet"
```

### Comprehensive Script
A unified snippet of all the steps covered by [First Startup](#first-startup):
```shell
# Create New Superuser
baseUrl="localhost:9000/api/v3/"
endpoint="core/users/"
requestUrl="$baseUrl$endpoint"

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
baseUrl="localhost:9000/api/v3/"
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
baseUrl="localhost:9000/api/v3/"
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
baseUrl="localhost:9000/api/v3/"
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
baseUrl="localhost:9000/api/v3/"
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
baseUrl="localhost:9000/api/v3/"
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
```

## Service Integration

```shell
baseUrl="localhost:9000/api/v3/"
endpoint="flows/instances/default-authentication-flow/"
requestUrl="$baseUrl$endpoint"

authenFlow=$(curl -s -X GET -L "$requestUrl"\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $newKey" )

endpoint="flows/instances/default-provider-authorization-implicit-consent/"
requestUrl="$baseUrl$endpoint"

authorFlow=$(curl -s -X GET -L "$requestUrl"\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $newKey" )
      
endpoint="flows/instances/default-invalidation-flow/"
requestUrl="$baseUrl$endpoint"

invFlow=$(curl -s -X GET -L "$requestUrl"\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $newKey" )

endpoint="providers/proxy/"
requestUrl="$baseUrl$endpoint"

providerName="Domain Level Proxy Provider"
authenticationUrl="http://localhost:9000"
mode="forward_domain"
cookieDomain=$DOMAIN_NAME
dataSet="{
  \"name\": \"$providerName\",
  \"authentication_flow\": $(echo $authenFlow | jq '.pk'),
  \"authorization_flow\": $(echo $authorFlow | jq '.pk'),
  \"invalidation_flow\": $(echo $invFlow | jq '.pk'),
  \"external_host\": \"$authenticationUrl\",
  \"mode\": \"$mode\",
  \"cookie_domain\": \"$cookieDomain\"
}"

provider=$(curl -s -X POST -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $newKey" -d "$dataSet")\
&& echo -e "\e[32m$(echo $provider | jq '.name') has been successfully created.\e[0m"\
|| echo -e "\e[31Failed to create $providerName: \e[0m$(echo $provider | jq -C)"
```

```shell
baseUrl="localhost:9000/api/v3/"
endpoint="core/applications/"
requestUrl="$baseUrl$endpoint"

appName="Whoami"
appSlug="whoami"

dataSet="{
  \"name\": \"$appName\",
  \"slug\": \"$appSlug\",
  \"provider\": $(echo $provider | jq '.pk')
}"

curl -s -X POST -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $newKey" -d "$dataSet"
```