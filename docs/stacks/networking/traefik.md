<p align="center">
<img height="400" title="Traefik" src="/assets/img/traefik.logo-dark.png" alt="">
</p>

Traefik (pronounced traffic) is a modern HTTP reverse proxy and load balancer that makes deploying microservices 
easy. Traefik integrates with your existing infrastructure components, notably Podman and Docker which are used in 
this guide.

The compose file for `Traefik` can be found in [traefik-compose.yml](/services/traefik/traefik-compose.yml)

To make the file easily customizable, it uses environment variables:

- **shrooTraefikName**: This is used to define a container name for the service check [Default rule for exposed containers](default-rule-for-exposed-containers) to see the usage
- **shrooTraefikDir**: Absolute path where Traefik's cinfiguration files are stored
- **shrooSocket**: The socket used for "Docker" discovery, it might defer depending on which container manager is used and if it's in rootless mode or not

>[!NOTE]
> shrooSocket can be set to:
> 
> - /var/run/docker.sock if using Docker
> - $XDG_RUNTIME_DIR/docker.sock if using rootless Docker or Podman with Docker compatibility
> - $XDG_RUNTIME_DIR/podman.sock if using Podman
> 
> <sub>XDG_RUNTIME_DIR is generally set to /run/user/$UID/</sub>

The key features used in this guide are:

- Redirect http to https
- Logging to files
- Default rule for exposed containers
- Dynamic file provider
- SSL Certificate using Let's Encrypt
- TLS by default

