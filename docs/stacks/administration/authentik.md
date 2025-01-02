<p align="center">
<img height="150" title="Authentik" src="/docs/assets/img/authentik.logo.svg" alt="">
</p>

---

authentik is a robust Identity Provider (IdP) and Single Sign-On (SSO) solution that prioritizes security, flexibility, and versatility. This guide demonstrates how to leverage authentik to centralize authentication and seamlessly enable SSO across multiple services, simplifying user management and strengthening overall security.

## Table of Content

- [Compose File](#compose-file)

## Compose File

The compose file for authentik is located at [authentik-compose.yml](/services/authentik/authentik-compose.yml), it's modified version based on [authentik's official compose file]().

This file is easily customizable through environment variables:

- **shrooAuthName**: Specifies a container name for the server service and a prefix for the other services. For usage purpose, see the [Default Rule for Exposed Containers](default-rule-for-exposed-containers).
- **shrooAuthDir**: Defines the absolute path where authentik’s files are stored locally.
- **shrooAuthDB**: Defines the absolute path where authentik's database is stored locally.

> [!NOTE]
> Port 9443 is commented in [add link] as TLS is handled by Traefik automatically (see [TLS by default](#tls-connections-by-default)).

The env file `.auth.env`is passed to the server (auth-server) and worker (auth-worker) services, the files holds
