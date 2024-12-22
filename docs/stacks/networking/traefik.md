<p align="center">
<img height="400" title="Traefik" src="/assets/img/traefik.logo-dark.png" alt="">
</p>

Traefik (pronounced *traffic*) is a modern HTTP reverse proxy and load balancer designed to simplify the deployment of microservices. In this guide, Traefik integrates seamlessly with container runtimes such as Podman and Docker.

## Configuration 

The [official documentation](https://doc.traefik.io/traefik/getting-started/configuration-overview/) for Traefik's configuratino provides a lot of information on how to implement different features.
The key features covered here in [traefik.yml](/services/traefik/traefik.yml) are:

- Automatic [HTTP-to-HTTPS redirection](#automatic-http-to-https-redirection)
- [Let’s Encrypt integration](#lets-encrypt-integration) for SSL certificates
- [TLS-enabled connections by default](#tls-enabled-connections-by-default)
- File-based logging
- A default routing rule for exposed containers
- Dynamic file provider configuration


### Automatic HTTP-to-HTTPS redirection

To achieve the redirection we leverage the [RedirectScheme](https://doc.traefik.io/traefik/middlewares/http/redirectscheme/) middleware, by adding the following block to the [htpp entrypoint](https://github.com/BDIFluky/shroobada_beta/blob/e1eeb406d7dee286976fd818299a091ca785f7ca/services/traefik/traefik.yml#L12-L18) named web in this case:
```yaml
    http:
      redirections:
        entryPoint:
          to: "websecure" # name of entry point to redirect to
          scheme: "https" # scheme used after redirection
```

### Let’s Encrypt integration

The [official documentation](https://doc.traefik.io/traefik/https/acme/) provides an extesnive guide on how to set up Let's Encrypt for automatic certificate generation.
in the [traefik.yml](https://github.com/BDIFluky/shroobada_beta/blob/e1eeb406d7dee286976fd818299a091ca785f7ca/services/traefik/traefik.yml#L29-L37), you can find an example of Let,s Encrypt configured with DNS-Challenge, with the email and the provider set with an environment variable that should be passed to Traefik container. 


### TLS-enabled connections by default



## Compose file

You can find the Compose file for Traefik in: [traefik-compose.yml](/services/traefik/traefik-compose.yml)

This file is easily customizable through environment variables:

- **shrooTraefikName**: Defines a container name for the service. For usage purpose, see the [Default Rule for Exposed Containers](default-rule-for-exposed-containers).
- **shrooTraefikDir**: Specifies the absolute path where Traefik’s configuration files are stored.
- **shrooSocket**: Indicates the socket used for service discovery. Its value depends on the container manager and whether it’s running in rootless mode.

> [!NOTE]  
> **shrooSocket** can be set as follows:
> - `/var/run/docker.sock` if using Docker
> - `$XDG_RUNTIME_DIR/docker.sock` if using rootless Docker or Podman with Docker compatibility
> - `$XDG_RUNTIME_DIR/podman.sock` if using Podman
>
> <sub>*`$XDG_RUNTIME_DIR` is commonly `/run/user/$UID/`.*</sub>




