# Ubuntu Docker Image with Nginx and PHP

[![Docker Hub](https://img.shields.io/badge/docker%20hub-ownercz%2Fnginx--php-blue.svg?&logo=docker&style=for-the-badge)](https://hub.docker.com/r/ownercz/nginx-php)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?&style=for-the-badge)](u26/LICENSE.md)

A production-ready Docker image based on **Ubuntu 26.04 LTS** with **Nginx**, **PHP-FPM**, and **Supervisor**. Originally forked from [jdsdev/ubuntu-nginx-php](https://github.com/jdsdev/ubuntu-nginx-php), heavily modified for multi-site hosting with optional Postfix mail relay.

A legacy Ubuntu 24.04 build is still maintained side-by-side under the [`u24/`](u24/) directory and the `u24*` Docker Hub tags — see the [Legacy `u24` line](#legacy-u24-line) section below.

## Features

- **Ubuntu 26.04 LTS** base image (codename `resolute`)
- **Nginx** (mainline) with optimized configuration
- **PHP-FPM** with configurable version (default 8.5, supports 8.2 – 8.5)
- **Supervisor** managing Nginx + PHP-FPM processes
- **Multi-architecture** support (AMD64 + ARM64/Ampere)
- **Postfix** included for outgoing mail relay (optional)
- **Composer** ready PHP environment
- Optimized PHP settings for production (OPcache, memory limits, upload sizes)

## Quick Start

### Pull from Docker Hub

```bash
docker pull ownercz/nginx-php:u26
```

### Run with Docker

```bash
docker run -d -p 8080:8080 ownercz/nginx-php:u26
```

### Run with Docker Compose

```yaml
version: '3.8'

services:
  nginx-php:
    image: ownercz/nginx-php:u26
    ports:
      - "8080:8080"
    volumes:
      - ./my-site:/usr/share/nginx/html
```

The default web root is `/usr/share/nginx/html`, and the container exposes port **8080**.

## Multi-Site Hosting

For hosting multiple sites, you can mount custom nginx vhost configs and web roots:

```yaml
version: '3.8'

services:
  nginx-php:
    image: ownercz/nginx-php:u26
    restart: always
    ports:
      - "8080:8080"     # Default site
      - "8005:8005"     # example.com
      - "8006:8006"     # blog.example.com
    volumes:
      # Timezone
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      # Custom nginx config
      - ./nginx.conf:/etc/nginx/nginx.conf
      # Site vhost configs
      - ./sites/example.com.conf:/etc/nginx/conf.d/example.com.conf
      - ./sites/blog.example.com.conf:/etc/nginx/conf.d/blog.example.com.conf
      # Web roots
      - ./data/example.com:/var/www/example.com
      - ./data/blog.example.com:/var/www/blog.example.com
      # Logs
      - ./log:/var/log
      - ./log/nginx:/var/log/nginx
      # SSL (optional)
      - /opt/ssl/cert.pem:/opt/fullchain.pem
      - /opt/ssl/cert.key:/opt/privkey.pem
    networks:
      - web

networks:
  web:
    driver: bridge
```

### Example Nginx Vhost Config

```nginx
server {
    listen 8005;
    listen [::]:8005;

    server_name example.com;
    root /var/www/example.com;

    index index.php index.html index.htm;

    client_max_body_size 512M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }
}
```

## Postfix Mail Relay (Optional)

The image includes Postfix for sending outgoing mail from PHP applications. To enable it, run the container as `root` and mount the `startpost.sh` script and Postfix configuration files:

```yaml
services:
  nginx-php:
    image: ownercz/nginx-php:u26
    user: root
    volumes:
      - ./startpost.sh:/opt/startpost.sh
      - ./postfix/main.cf:/etc/postfix/main.cf
      - ./postfix/sasl_passwd:/etc/postfix/sasl_passwd
      - ./postfix/generic:/etc/postfix/generic
      - ./postfix/relayhost_map:/etc/postfix/relayhost_map
      - ./postfix/aliases:/etc/aliases
```

The `startpost.sh` script is included in the repository root and handles Postfix initialization inside the container.

> **Note:** When using Postfix, the container must run as `root` (`user: root`).

## Deployment with Ansible

An example Ansible role is provided in the [`ansible-deployment/`](ansible-deployment/) directory. It automates the full setup including directory structure, docker-compose, nginx configs, and Postfix configuration.

### Quick Ansible Setup

1. Copy the role into your Ansible roles directory:
   ```bash
   cp -r ansible-deployment /path/to/ansible/roles/nginx-php
   ```

2. Create a playbook:
   ```yaml
   ---
   - hosts: webservers
     become: yes
     roles:
       - nginx-php
   ```

3. Configure your host variables:
   ```yaml
   # host_vars/web01.yml
   nginx_php_image: "ownercz/nginx-php:u26"
   php_version: "8.5"

   sites:
     - name: example.com
       port: 8005
     - name: blog.example.com
       port: 8006

   ssl_cert_path: /etc/letsencrypt/live/example.com/fullchain.pem
   ssl_key_path: /etc/letsencrypt/live/example.com/privkey.pem

   postfix_enabled: true
   postfix_relayhost: "[smtp.gmail.com]:587"
   postfix_sasl_credentials: "[smtp.gmail.com]:587 user@gmail.com:app-password"
   postfix_sender_email: "noreply@example.com"
   ```

4. Run:
   ```bash
   ansible-playbook -i inventory site.yml
   ```

For full documentation of the Ansible role, see [`ansible-deployment/README.md`](ansible-deployment/README.md).

## Building the Image

### Standard Build

```bash
cd u26
docker build -t ownercz/nginx-php:u26 .
```

### Multi-Architecture Build (AMD64 + ARM64)

```bash
cd u26
./build-multiarch.sh
```

## CI workflow

A single Gitea Actions workflow now builds and publishes both variants (`u24` and
`u26`) across PHP `8.2` - `8.5`:

- `.gitea/workflows/gitea-ci.yml`

The workflow keeps `latest` tied to `u26` on default PHP (`8.5`) and publishes
OS-scoped tags for both variants.

### Custom PHP Version

```bash
docker build --build-arg PHP_VERSION=8.4 -t ownercz/nginx-php:u26-php8.4 .
```

## Configuration

### PHP Settings (pre-configured in the image)

| Setting | Value |
|---------|-------|
| `memory_limit` | 256M |
| `upload_max_filesize` | 100M |
| `post_max_size` | 100M |
| `max_execution_time` | 180 |
| `max_input_time` | 180 |
| `opcache.enable` | 1 |
| `opcache.memory_consumption` | 512 |

### PHP-FPM Pool Settings

| Setting | Value |
|---------|-------|
| `pm.max_children` | 4 |
| `pm.start_servers` | 3 |
| `pm.min_spare_servers` | 2 |
| `pm.max_spare_servers` | 4 |
| `pm.max_requests` | 200 |

### Key Paths Inside the Container

| Path | Description |
|------|-------------|
| `/usr/share/nginx/html` | Default web root |
| `/var/www/<site>` | Custom site web roots |
| `/etc/nginx/conf.d/` | Nginx vhost configs |
| `/etc/nginx/nginx.conf` | Main Nginx config |
| `/var/log/nginx/` | Nginx logs |
| `/var/log/php-fpm.log` | PHP-FPM log |
| `/opt/startpost.sh` | Postfix startup script |
| `/etc/supervisord.conf` | Supervisor config |

## Docker Hub

**Image:** [ownercz/nginx-php](https://hub.docker.com/r/ownercz/nginx-php)

The image is published as a multi-architecture manifest (`linux/amd64` +
`linux/arm64`) under multiple tags so you can pick the level of stability you
need. **Pick a tag based on what you want to be stable over time.**

### Tag taxonomy

Anatomy of a tag: `<channel>[-php<X.Y>][-<sha>]`

| Tag | Channel | OS pinned? | PHP pinned? | Commit pinned? |
|-----|---------|------------|-------------|----------------|
| `latest` | rolling | no | no (default 8.5) | no |
| `u26` | rolling | yes (Ubuntu 26.04) | no (default 8.5) | no |
| `u26-php8.4` | rolling | yes | yes | no |
| `php8.4` | rolling | no (always newest OS) | yes | no |
| `u26-<sha>` | immutable | yes | no (default 8.5) | yes |
| `u26-php8.4-<sha>` | immutable | yes | yes | yes |
| `u24*` | legacy | yes (Ubuntu 24.04) | varies | varies |

`<sha>` is the first 10 characters of the source commit hash. Image OCI
labels (`org.opencontainers.image.revision`, `org.opencontainers.image.created`)
record the same information for offline inspection:

```bash
docker buildx imagetools inspect ownercz/nginx-php:u26 --format '{{ json . }}' \
    | jq '.manifest.annotations, .image.config.config.Labels'
```

### Choosing a tag

| You want… | Use |
|-----------|-----|
| Quickest start, willing to upgrade with the project | `latest` |
| Lock to one PHP minor, follow OS + security updates | `php8.4` (or `u26-php8.4` to also pin the OS) |
| Reproducible production deploys | A commit-pinned tag: `u26-php8.4-<sha>` |
| Stay on Ubuntu 24.04 a bit longer | `u24` or `u24-php<X.Y>` |

> **Heads-up on `:latest`** — `:latest` was repointed from the Ubuntu 24.04
> line (PHP 8.3 default) to Ubuntu 26.04 + PHP 8.5. If you used `:latest` in
> production, pin to `u24` (or to a `u26-php<X.Y>-<sha>` tag) before pulling.

## Legacy `u24` line

The Ubuntu 24.04 build is still produced from the [`u24/`](u24/) directory.
Use it if you cannot yet move to Ubuntu 26.04 (for example because the
`ondrej/php` PPA or `nginx.org` mainline repo has not published packages for
`resolute` on your build host yet).

```bash
docker pull ownercz/nginx-php:u24
```

Note that `:latest` no longer points at `u24` — pin explicitly to `u24` (or to
a specific `u24-php<X.Y>` tag) if you need the legacy behaviour.

## License

MIT — See [LICENSE.md](u26/LICENSE.md) (the legacy `u24` line uses [`u24/LICENSE.md`](u24/LICENSE.md)).
