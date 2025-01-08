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
- [Service Integration](#service-integration)

## Compose File

The compose file for authentik is located at [`authentik-compose.yml`](/services/authentik/authentik-compose.yml). It’s a modified version of [authentik's official compose file](https://docs.goauthentik.io/docs/install-config/install/docker-compose) and can be customized through various environment variables:

- **shrooAuthName**: Specifies a container name for the server service and a prefix for the other services. For usage purpose, see the [Default Rule for Exposed Containers](default-rule-for-exposed-containers).
- **shrooAuthDir**: Defines the absolute path where authentik’s files are stored locally.
- **shrooAuthDB**: Defines the absolute path where authentik's database is stored locally.

> [!NOTE]
> In [`authentik-compose.yml`](/services/authentik/authentik-compose.yml), port 9443 is commented out because Traefik handles TLS automatically. For more information, refer to [TLS by default](#tls-connections-by-default).

The `.auth.env` file is passed to both the auth-server and auth-worker services. It contains the required environment variables for this guide:

- **AUTHENTIK_REDIS__HOST**: Redis server host when not using configuration URL, as we change the redis' container name this should be set to `auth-redis`.
- **AUTHENTIK_POSTGRESQL__HOST**: Hostname of your PostgreSQL Server (`auth-pg`).
- **AUTHENTIK_POSTGRESQL__USER**: Database user.
- **AUTHENTIK_POSTGRESQL__NAME**: Database name.
- **AUTHENTIK_POSTGRESQL__PASSWORD**: Database password, defaults to the environment variable `POSTGRES_PASSWORD`.
- **AUTHENTIK_SECRET_KEY**: Secret key used for cookie signing. Changing this will invalidate active sessions.
- **AUTHENTIK_BOOTSTRAP_PASSWORD**: Configure the default password for the akadmin user. Only read on the first startup. Can be used for any flow executor. See [Automated install | authentik](https://docs.goauthentik.io/docs/install-config/automated-install).
- **AUTHENTIK_BOOTSTRAP_TOKEN**: Create a token for the default akadmin user. Only read on the first startup. The string you specify for this variable is the token key you can use to authenticate yourself to the API. See [Automated install | authentik](https://docs.goauthentik.io/docs/install-config/automated-install).
- **AUTHENTIK_ERROR_REPORTING__ENABLED**: Enable error reporting. Defaults to false.

> [!NOTE]
> For a list of recognized environment variables, see the [Configuration | authentik](https://docs.goauthentik.io/docs/install-config/configuration/) and [Automated install | authentik](https://docs.goauthentik.io/docs/install-config/automated-install).

The `.auth-pg.env` file is passed to the PostgreSQL container to configure authentik's database, it includes:

- **POSTGRES_PASSWORD**: Database password.
- **POSTGRES_USER**: Database user.
- **POSTGRES_DB**: Database name.

Two networks—`AuthFrontNet` and `AuthBackNet`—are defined to separate front-end and back-end communications. Only the front-end is externally accessible.

## Traefik Integration

authentik’s web interface can be made accessible through Traefik by exposing the `auth-server` service via the container manager’s socket and enabling network communication between the Traefik and authentik server. The relevant steps are:

- **Adding labels**:

```yml
  auth-server:
    labels:
      - "traefik.enable=true" # exposes the web interface to Traefik
      - "traefik.docker.network=AuthFrontNet" # Instructs Traefik to use AuthFrontNet for communication with `auth-server`
```

- **Attaching Traefik to authentik’s Front-End Network**:

```yml
  traefik:
    networks:
      - AuthFrontNet
```

### Authentication Middleware

Traefik can forward authentication requests to authentik by referencing a custom middleware configuration. For details, see  [`auther-mwr.yml`](/services/authentik/auther-mwr.yml).

## First Startup

Automated initialization can be performed by creating a new superuser, generating an API token, assigning a password and then deactivating the default `akadmin` user. The process relies on the `AUTHENTIK_BOOTSTRAP_TOKEN` environment variable for API access.

>[!NOTE]
> The scrip in this section uses `curl` and `jq` to send request and parse JSON strings.

In the following, we assume that authentik web interface is accessible through `localhost:9000`.

- **Create a new superuser:** The below code snippet, creates a new user `fluky` by using [core_users_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-users-create). the response is stored in a variable `newUser`.
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

- **Set password for the nez user:** The below code snippet, sets a password for the newly created user `fluky` by using [core_users_set_password_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-users-set-password-create).
>[!NOTE]
>The endpoint for this API request is `core/users/:id/set_password/` where `:id` should be replaced with the user's id we which to set a password to which in case of users is the field `pk`.
```shell
baseUrl="localhost:9000/api/v3/"
endpoint="core/users/$(echo $newUser | jq '.pk')/set_password/"
requestUrl="$baseUrl$endpoint"

newPassword="Chang3M3nOw"
dataSet="{
  \"password\": \"$newPassword\"
}"

curl -s -X POST -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $AUTHENTIK_BOOTSTRAP_TOKEN"\
      -d "$dataSet"
```
- **Add new user to admin group:** The below code snippet, adds the newly created user `fluky` to the admin group `authentik Admins` by using [core_groups_list | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-groups-list) to get the admin group UUID and [core_groups_add_user_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-groups-add-user-create) to add the new user to that group. 
```shell
baseUrl="localhost:9000/api/v3/"
endpoint="core/groups/"
requestUrl="$baseUrl$endpoint"

adminGroupUUID=$(curl -s -X GET -L "requestUrl"\
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

- **Create new API token linked to the new user:** The below code snippet, creates a new token, assign it to the new user `fluky` then sets a key for the new API token by using [core_tokens_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-tokens-create) to create the token amd [core_tokens_set_key_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-tokens-set-key-create) to set the key.
>[!NOTE]
> The new key should be stored safely as there is no way to retrieve afterward.
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

newKey="Chang3M3n0w"
dataSet="{
  \"key\": \"$newKey\"

}"

curl -s -X POST -L "$requestUrl"\
      -H 'Content-Type: application/json'\
      -H 'Accept: application/json'\
      -H "Authorization: Bearer $AUTHENTIK_BOOTSTRAP_TOKEN"\
      -d "$dataSet"
```

- **Delete `AUTHENTIK_BOOTSTRAP_TOKEN`:** The below code snippet, deletes `AUTHENTIK_BOOTSTRAP_TOKEN` by using [core_tokens_destroy | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-tokens-destroy).
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

- **Set a password for `akadmin` and deactivate it:** The below code snippet, sets a password for `akadmin` then deactivates it by using [core_users_list | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-users-list) to get the user id  `pk`, [core_users_set_password_create | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-users-set-password-create) to set the password and [core_users_partial_update | authentik](https://docs.goauthentik.io/docs/developer-docs/api/reference/core-users-partial-update) to deactivate it.
>[!NOTE]
>The endpoint for this API request is `core/users/:id/set_password/` where `:id` should be replaced with the user's id we which to set a password to which in case of users is the field `pk`.
> The password should be stored safely as there is no way to retrieve afterward.
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

## Service Integration
