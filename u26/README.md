# NGINX with PHP-FPM on Ubuntu 26.04

[![Docker Hub: ownercz/nginx-php](https://img.shields.io/badge/docker%20hub-ownercz%2Fnginx--php-blue.svg?&logo=docker&style=for-the-badge)](https://hub.docker.com/r/ownercz/nginx-php) [![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?&style=for-the-badge)](LICENSE.md)

## Introduction

Production-ready Docker image based on **Ubuntu 26.04 LTS** (codename `resolute`)
with **Nginx mainline**, **PHP-FPM** (default 8.5), and **Supervisor**.
Multi-architecture builds for `linux/amd64` and `linux/arm64` (Ampere).

The image bundles common PHP extensions (bcmath, curl, gd, gmp, intl, mbstring,
mysql, soap, xml, zip, yaml, imagick, redis) and an optional **Postfix** mail
relay path (see the root [README](../README.md)).

## Tags

The image is published as a multi-arch manifest under several tag families.
Pick by how stable you want the reference to be over time.

| Tag                       | Channel              | Use case                                      |
|---------------------------|----------------------|-----------------------------------------------|
| `latest`                  | rolling              | Quick start, willing to track the project     |
| `u26`                     | rolling (OS-pinned)  | Track Ubuntu 26.04 + default PHP              |
| `u26-php8.5` … `u26-php8.2` | rolling (OS+PHP)   | Track Ubuntu 26.04 with a specific PHP minor  |
| `php8.5` … `php8.2`       | rolling (PHP only)   | Always newest OS for a given PHP minor        |
| `u26-<sha>`               | immutable            | Reproducible deploys, default PHP             |
| `u26-php<X.Y>-<sha>`      | immutable            | Reproducible deploys, exact PHP               |
| `u24*` (legacy)           | rolling (legacy OS)  | Stay on Ubuntu 24.04, see [`../u24/`](../u24/) |

`<sha>` is the first 10 characters of the source commit hash. Image OCI
labels (`org.opencontainers.image.revision`, `…image.created`) embed the same
information for offline inspection.

See the project root [README](../README.md#choosing-a-tag) for a "which tag
should I pick?" decision table.

## Getting Started

```bash
docker pull ownercz/nginx-php:u26
docker run -d -p 8080:8080 ownercz/nginx-php:u26
```

The default web root is `/usr/share/nginx/html` and the container exposes port
**8080** (running as the `www-data` user by default).

## Build locally

```bash
docker build -t ownercz/nginx-php:u26 .
```

### Build arguments

| Arg | Default | Purpose |
|-----|---------|---------|
| `PHP_VERSION` | `8.5` | PHP minor version installed inside the image |
| `UBUNTU_CODENAME` | `resolute` | Codename used for `nginx.org` and `ondrej/php` apt repos. Set to `noble` to fall back to the previous LTS while upstream catches up |
| `VCS_REF` | `local` | Source commit hash (`org.opencontainers.image.revision`) |
| `BUILD_DATE` | `unknown` | RFC3339 build timestamp (`org.opencontainers.image.created`) |

### Pin a different PHP version

```bash
docker build --build-arg PHP_VERSION=8.4 -t ownercz/nginx-php:u26-php8.4 .
```

### Multi-arch + full tag set (mirrors what CI publishes)

```bash
./build-multiarch.sh                     # default PHP, push all tags
PHP_VERSION=8.4 ./build-multiarch.sh     # build & push tags for PHP 8.4
PUSH=0 ./build-multiarch.sh              # local-only single-arch build
```

The script derives the same set of tags the CI job publishes (`latest`,
`u26`, `u26-php<X.Y>`, `php<X.Y>`, plus the immutable `…-<sha>` variants)
and pushes them in one `docker buildx build --push`.

### Fall back to the previous LTS apt repos

If `nginx.org` or the `ondrej/php` PPA do not yet publish `resolute` packages
at build time, override the codename used for third-party apt sources:

```bash
docker build --build-arg UBUNTU_CODENAME=noble -t ownercz/nginx-php:u26 .
```

## Configuration

See the project root [README.md](../README.md) for full configuration,
multi-site hosting examples, Postfix relay setup, and the Ansible role.

## License

MIT — see [LICENSE.md](LICENSE.md).

