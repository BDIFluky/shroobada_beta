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
**Shroobada** aims to provide a modular, customizable and FOSS based framework for setting up a homelab. It organizes functionality into distinct stacks, each serving a particular purpose. Each stack consists of one or more services running in containers. Configuration details for these containers are defined in dedicated YAML files, ensuring a clear and easily maintainable setup.

To streamline the process, the entire setup will be automated through a documented script, minimizing manual intervention and potential errors.

## Roadmap

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
There are various container managers out there, it's a pick your poison kind of thing, as stated in the [Overview & Scope](#overview--scope) we'll be using Podman as container manager, but the compose.yml we'll provide should give you an accurate idea on how to migrate to other container managers if needed.
