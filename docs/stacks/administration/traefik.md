<p align="center">
<img height="400" title="Traefik" src="/assets/img/traefik.logo-dark.png" alt="">
</p>

---

Traefik (pronounced *traffic*) is a modern HTTP reverse proxy and load balancer designed to simplify the deployment of microservices. This guide covers integrating Traefik with container runtimes such as Podman or Docker.

## Table of Contenet

- [Configuration](#configuration)
  - [HTTP-to-HTTPS redirection](#automatic-http-to-https-redirection)
  - [Let’s Encrypt integration](#lets-encrypt-integration)
  - [TLS by default](#tls-connections-by-default)
  - [File-based logging](https://doc.traefik.io/traefik/observability/logs/)
  - [default routing rule for exposed containers](#default-routing-rule-for-exposed-containers)
  - [Dynamic file](#dynamic-file) 
- [Compose File](#compose-file)

## Configuration

Refer to the [official Traefik documentation](https://doc.traefik.io/traefik/getting-started/configuration-overview/) for detailed instructions on configuring different features.
The key elements in [traefik.yml](/services/traefik/traefik.yml) include:

- Automatic [HTTP-to-HTTPS redirection](#automatic-http-to-https-redirection)
- [Let’s Encrypt integration](#lets-encrypt-integration) for SSL certificates
- [TLS by default](#tls-connections-by-default)
- [File-based logging](https://doc.traefik.io/traefik/observability/logs/)
- A [default routing rule for exposed containers](#default-routing-rule-for-exposed-containers)
- [Dynamic file](#dynamic-file) provider configuration

### Automatic HTTP-to-HTTPS Redirection

Traefik redirects HTTP traffic to HTTPS using the [RedirectScheme middleware](https://doc.traefik.io/traefik/middlewares/http/redirectscheme/) on the `web` entrypoint (address :80).
See [traefik.yml (L14-L18)](https://github.com/BDIFluky/shroobada_beta/blob/e1eeb406d7dee286976fd818299a091ca785f7ca/services/traefik/traefik.yml#L14-L18):

```yaml
    http:
      redirections: # redirectScheme middleware
        entryPoint:
          to: "websecure" # name of entrypoint to redirect to
          scheme: "https" # scheme used after redirection
```

### Let’s Encrypt Integration

In the [traefik.yml (L30-L37)](https://github.com/BDIFluky/shroobada_beta/blob/e1eeb406d7dee286976fd818299a091ca785f7ca/services/traefik/traefik.yml#L30-L37), Let's Encrypt configured with DNS-Challenge. The email and DNS provider are passed as environment variables:

```yaml
  letsencrypt: # certResolver name
    acme:
      email: "{{env \"PROVIDER_EMAIL\"}}" # email provided by an environment variable
      storage: "/letsencrypt/acme.json" # storage location for the acme.json
      preferredchain: 'ISRG Root X2'
      keytype: 'ECDSA P-384'
      dnsChallenge: # challenge type
        provider: "{{env \"PROVIDER\"}}" # provider code provided by an environment variable
```

> [!NOTE]
> Depending on your DNS provider, additional environment variables must be passed to the Traefik container. See the [official documentation](https://doc.traefik.io/traefik/https/acme/#providers) for a list of supported providers and their respective configurations..

### TLS by Default

This feature is enabled in [traefik.yml (L22-L24)](https://github.com/BDIFluky/shroobada_beta/blob/e1eeb406d7dee286976fd818299a091ca785f7ca/services/traefik/traefik.yml#L22-L24).the `websecure` entrypoint (address :443) is marked as the default entrypoint for all services, using the certificate resolver `Let's Encrypt`.

```yaml
  websecure:
    address: :443
    asDefault: true # entrypoint set a s default
    http:
      tls: # tls enabled by default for the above entrypoint
        certResolver: "letsencrypt" # default certificate resolver
```

### Default Routing Rule for Exposed Containers

By defining a default rule for discovered containers, you can eliminate the need for individual router labels. Any custom router label on a container will override this default.
In [traefik.yml (L65-L67)](https://github.com/BDIFluky/shroobada_beta/blob/e1eeb406d7dee286976fd818299a091ca785f7ca/services/traefik/traefik.yml#L65-L67):
```yaml
providers:
  docker:
    exposedByDefault: false # label "traefik.enable=true" needed to expose a container
    defaultRule: "Host(`{{ .ContainerName }}.{{env \"DOMAIN_NAME\"}}`)" # default rule for exposed containers is [containername].[domainName] 
```
For example for a container named `shroo` and domain `ba.da` the resulting rule would be `shroo.ba.da`.

### Dynamic File

Aside from services exposed via the Docker provider, you can define additional services, routers, or middlewares using a dynamic file. This feature is enabled in [traefik.yml (L69-L71)](https://github.com/BDIFluky/shroobada_beta/blob/e1eeb406d7dee286976fd818299a091ca785f7ca/services/traefik/traefik.yml#L69-L71)l:

```yaml
  file:
    directory: "/dynamic" # dynamic file path
    watch: true
```

For example, the `dashboard` and `api` routers are redefined in [internals.yml](/services/traefik/dynamic/internals.yml) which is to be placed within the dynamic file directory.

## Compose File

The compose file for Traefik is located at [traefik-compose.yml](/services/traefik/traefik-compose.yml).

This file is easily customizable through environment variables:

- **shrooTraefikName**: Specifies a container name for the service. For usage purpose, see the [Default Rule for Exposed Containers](default-rule-for-exposed-containers).
- **shrooTraefikDir**: Defines the absolute path where Traefik’s configuration files are stored.
- **shrooCMSocket**: Indicates the socket used for service discovery. This depends on the container manager and whether it’s running in rootless mode.

> [!NOTE]
> **shrooCMSocket** can be set as follows:
> - `/var/run/docker.sock` if using Docker
> - `$XDG_RUNTIME_DIR/docker.sock` if using rootless Docker or Podman with Docker compatibility
> - `$XDG_RUNTIME_DIR/podman/podman.sock` if using Podman
>
> <sub>*`$XDG_RUNTIME_DIR` is commonly `/run/user/$UID/`.*</sub>

Also, the env file `.treafik.env` is passed to the Traefik container, the file holds environment variables required by the configuration:

- **DOMAIN_NAME**: Default domain name to be used by Traefik to setup the default routes.
- **PROVIDER_EMAIL**: Provider email for the DNS-Challenge if used as well as other variables needed by that provider

Additionally, the Compose file includes a `whoami` container for testing purposes. For instance this container allows you to verify the default routing rule provided by the Docker provider. For example, if the domain name is `shroo.bada`, the `whoami` container will be reachable at `whoami.shroo.bada`.