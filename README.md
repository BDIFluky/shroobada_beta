# Shroobada
Shroobada is BDI's attempt at setting up a homelab, and for once they are documenting their shit (this is unprecedented).

> “Those who know, do. Those that understand, teach.” <sub>― Aristotle </sub>

## Table of Contents

- [Shroobada](#shroobada)
  - [Table of Contents](#table-of-contents)
  - [Overview & Scope](#overview--scope)
  - [Roadmap](#roadmap)
  - [Deployment Guide](#deployment-guide)
    - [Environment Setup](#environment-setup)
    - [Container Manager](#container-manager)

## Overview & Scope
> “No great mind has ever existed without a touch of madness.” <sub>― Aristotle </sub>

## Roadmap

## Deployment Guide
All code blocks are available in the [code_blocks.md](./code_blocks.md) file with comments.

### Environment Setup
This has been set up on a Debian host:
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
