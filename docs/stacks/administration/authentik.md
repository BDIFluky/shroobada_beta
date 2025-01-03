<p align="center">
<img height="150" title="Authentik" src="/docs/assets/img/authentik.logo.svg" alt="">
</p>

---

authentik is a robust Identity Provider (IdP) and Single Sign-On (SSO) solution that prioritizes security, flexibility, and versatility. This guide demonstrates how to leverage authentik to centralize authentication and seamlessly enable SSO across multiple services, simplifying user management and strengthening overall security.

## Table of Content

- [Compose File](#compose-file)
- [Traefik Integration](#traefik-integration)
- [First Startup](#first-startup)
- [Service Integration](#service-integration)

## Compose File

The compose file for authentik is located at [`authentik-compose.yml`](/services/authentik/authentik-compose.yml), it's modified version based on [authentik's official compose file](https://docs.goauthentik.io/docs/install-config/install/docker-compose).

This file is easily customizable through environment variables:

- **shrooAuthName**: Specifies a container name for the server service and a prefix for the other services. For usage purpose, see the [Default Rule for Exposed Containers](default-rule-for-exposed-containers).
- **shrooAuthDir**: Defines the absolute path where authentik’s files are stored locally.
- **shrooAuthDB**: Defines the absolute path where authentik's database is stored locally.

> [!NOTE]
> Port 9443 is commented in [`authentik-compose.yml`](https://github.com/BDIFluky/shroobada_beta/blob/20665f4fecf8320a0e78027b031befd3a9fc4a8b/services/authentik/authentik-compose.yml#L13) as TLS is handled by Traefik automatically (see [TLS by default](#tls-connections-by-default)).

The env file `.auth.env`is passed to the server (auth-server) and worker (auth-worker) services, the files holds environment variable required by this guide:

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
> A list of accepted environment variables for each container is available at [Configuratuin | authentik](https://docs.goauthentik.io/docs/install-config/configuration/) and [Automated install | authentik](https://docs.goauthentik.io/docs/install-config/automated-install.

The env file `.auth-pg.env` is passed to the postgres database to setup authentik's database, this files holds the following environment variables:

- **POSTGRES_PASSWORD**: Database password.
- **POSTGRES_USER**: Database user.
- **POSTGRES_DB**: Database name.

Two networks are created, `AuthFrontNet` and `AuthBackNet`, the purpose of having two networks is to separate the frontend from the backend and thus allowing only the frontend to be accessed by the outside.

## Traefik Integration

## First Startup

## Service Integration
