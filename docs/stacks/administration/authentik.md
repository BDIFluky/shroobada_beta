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

The compose file for authentik is located at [`authentik-compose.yml`](/services/authentik/authentik-compose.yml). It’s a modified version of [authentik's official compose file](https://docs.goauthentik.io/docs/install-config/install/docker-compose).

This file is easily customizable through environment variables:

- **shrooAuthName**: Specifies a container name for the server service and a prefix for the other services. For usage purpose, see the [Default Rule for Exposed Containers](default-rule-for-exposed-containers).
- **shrooAuthDir**: Defines the absolute path where authentik’s files are stored locally.
- **shrooAuthDB**: Defines the absolute path where authentik's database is stored locally.

> [!NOTE]
> In [`authentik-compose.yml`](/services/authentik/authentik-compose.yml), port 9443 is commented out because Traefik handles TLS automatically. For more information, see [TLS by default](#tls-connections-by-default).

The `.auth.env` file is passed to both the auth-server and auth-worker services. It contains the required environment variables for this guide:

- **AUTHENTIK_REDIS__HOST**: Redis server host when not using configuration URL, as we change the redis' container name this should be set to `auth-redis`.
- **AUTHENTIK_POSTGRESQL__HOST**: Hostname of your PostgreSQL Server (`auth-pg`).
- **AUTHENTIK_POSTGRESQL__USER**: Database user.
- **AUTHENTIK_POSTGRESQL__NAME**: Database name.
- **AUTHENTIK_POSTGRESQL__PASSWORD**: Database password, defaults to the environment variable `POSTGRES_PASSWORD`.
- **AUTHENTIK_SECRET_KEY**: Secret key used for cookie signing. Changing this will invalidate active sessions.
- **AUTHENTIK_BOOTSTRAP_PASSWORD**: Configure the default password for the akadmin user. Only read on the first startup. Can be used for any flow executor.
- **AUTHENTIK_BOOTSTRAP_TOKEN**: Create a token for the default akadmin user. Only read on the first startup. The string you specify for this variable is the token key you can use to authenticate yourself to the API.
- **AUTHENTIK_ERROR_REPORTING__ENABLED**: Enable error reporting. Defaults to false.

> [!NOTE]
> For a list of recognized environment variables, see the [Configuratuin | authentik](https://docs.goauthentik.io/docs/install-config/configuration/) and [Automated install | authentik](https://docs.goauthentik.io/docs/install-config/automated-install).

The `.auth-pg.env` file is passed to the PostgreSQL container to setup authentik's database, it includes:

- **POSTGRES_PASSWORD**: Database password.
- **POSTGRES_USER**: Database user.
- **POSTGRES_DB**: Database name.

Two networks—`AuthFrontNet` and `AuthBackNet`—are defined to separate front-end and back-end communications. Only the front-end is externally accessible.

## Traefik Integration

To make authentik web interface accessible through Traefik, you must expose the auth-server service through your container manager’s socket and allow Traefik’s container and Authentik’s server container to communicate:, and this by:

- **Adding appropriate labels**:

```yml
  auth-server:
    labels:
      - "traefik.enable=true" # expose the web page to traefik
      - "traefik.docker.network=AuthFrontNet" # tells traefik which network to use to communication with `auth-server`
```

- **Adding Traefik container to authentik's front network**:

```yml
  traefik:
    networks:
      - AuthFrontNet
```

### Authentication Middleware

In order for Traefik to forward authentication requests to authentik, you need a middleware definition. See [`auther-mwr.yml`](/services/authentik/auther-mwr.yml).

## First Startup

## Service Integration
