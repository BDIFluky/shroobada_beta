# Shroobada
Shroobada is BDI's attempt at setting up a homelab, and for once they are documenting their shit (this is unprecedented).

> “Those who know, do. Those who understand, teach.” <sub>― Lee Shulman </sub>

---

## Table of Contents

- [Overview & Scope](#overview--scope)
- [Roadmap](#roadmap)
- [Getting Started](#getting-started)
  - [Environment Setup](#environment-setup)
  - [Container Manager](#container-manager)

---

## Overview & Scope
**Shroobada** is a modular, customizable, and FOSS-based framework designed to streamline the setup and management of a homelab. This solution is structured into distinct stacks, each tailored to a specific purpose. Services within each stack run in containers, and their configuration is neatly encapsulated in dedicated YAML files to maintain clarity, consistency, and ease of maintenance.

The stacks covered by **Shroobada** are the following:

- 
- 

**Shroobada** also aims be:

- Security Focused: Provides guidance on firewalls, VPN configuration, and safe service exposure.
- Customizable Blueprints: Offers YAML-based configurations for rapid, consistent deployment and easy modification.
- Scalable: Acommodate both single-node homelabs and complex, multi-node clusters.

The entire setup process is automated and thoroughly documented, reducing manual intervention and potential errors. Through this careful orchestration—supported by rich documentation and templated configurations—Shroobada ensures a more predictable, repeatable, and maintainable approach to homelab deployment and growth.

## Getting Started

### Environment Setup
**Shroobada** is currently tested on a Debian host:
```console
fluky@Shroobada:~$ hostnamectl
 Static hostname: Shroobada
       Icon name: computer-desktop
         Chassis: desktop 🖥️
            .
            .
Operating System: Debian GNU/Linux 12 (bookworm)
          Kernel: Linux 6.1.0-23-amd64
    Architecture: x86-64
            .
            .
```

In the following sections we assume the existence of a user named Fluky which has been granted sudo privileges.

> [!TIP]
> [How to grant sudo privileges](./code_blocks.md#grant-sudo-privileges)


### Container Manager
There are numerous container managers available, and selecting one often comes down to personal preference. Shroobada supports both Podman and Docker as container managers, allowing users to choose their preferred option. However, the provided YAML files serve as a helpful reference, making it simpler to transition to other container managers if needed.