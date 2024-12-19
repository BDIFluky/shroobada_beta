<p align="center">
<img height="400" title="Traefik" src="/assets/img/traefik.logo-dark.png" alt="">
</p>

Traefik (pronounced traffic) is a modern HTTP reverse proxy and load balancer that makes deploying microservices 
easy. Traefik integrates with your existing infrastructure components, notably Podman and Docker which are used in 
this guide.

The compose file for traefik can be found in [`traefik-compose.yml`](/../../blob/main/services/traefik/traefik-compose.yml)

The key features used in this guide are:

- Redirect http to https
- Logging to files
- Default rule for exposed containers
- Dynamic file provider
- SSL Certificate using Let's Encrypt
- TLS by default

