<p align="center">
<img height="400" title="Traefik" src="/assets/img/traefik.logo-dark.png" alt="">
</p>

Traefik (pronounced *traffic*) is a modern HTTP reverse proxy and load balancer designed to simplify the deployment of microservices. In this guide, Traefik integrates seamlessly with container runtimes such as Podman and Docker.


## Compose file
### Compose file
You can find the Compose configuration file for Traefik in: [traefik-compose.yml](/services/traefik/traefik-compose.yml)

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



**Key Features Covered in This Guide:**

- Automatic HTTP-to-HTTPS redirection
- File-based logging
- A default routing rule for exposed containers
- Dynamic file provider configuration
- Let’s Encrypt integration for SSL certificates
- TLS-enabled connections by default
