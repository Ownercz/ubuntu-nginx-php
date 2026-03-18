# Ansible Deployment Role for ubuntu-nginx-php

An example Ansible role for deploying the `ownercz/nginx-php` Docker container to your servers. This role handles the full lifecycle: directory structure, docker-compose, nginx vhost configs, and optional postfix mail relay.

## Role Structure

```
ansible-deployment/
├── defaults/
│   └── main.yml          # Default variables (customize per host/group)
├── handlers/
│   └── main.yml          # Restart & postmap handlers
├── tasks/
│   ├── main.yml          # Main orchestration
│   ├── prepare.yml       # Per-site directory & vhost setup
│   └── postfix.yml       # Postfix relay configuration
└── templates/
    ├── .env.j2
    ├── docker-compose.yml.j2
    ├── nginx.conf.j2
    ├── nginx-vhost.conf.j2
    ├── startpost.sh.j2
    ├── postfix-main.cf.j2
    ├── postfix-generic.j2
    ├── postfix-relayhost_map.j2
    ├── postfix-resolv.conf.j2
    └── postfix-sasl_passwd.j2
```

## Requirements

- Ansible 2.12+
- Docker and Docker Compose installed on the target host
- SSL certificates available on the host (for HTTPS sites)

## Role Variables

All variables are defined in `defaults/main.yml`. Override them in your inventory or playbook.

### Required Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `nginx_php_image` | `ownercz/nginx-php:u24` | Docker image to pull |
| `php_version` | `8.3` | PHP version inside the container |
| `sites` | *(see below)* | List of sites to serve |

### Site Definition

Each site in the `sites` list requires:

```yaml
sites:
  - name: example.com    # Domain name / directory name
    port: 8005            # Unique port for this vhost
```

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `nginx_php_base_path` | `/opt/docker/nginx-php` | Host base path for all data |
| `container_name_prefix` | `nginx-php` | Prefix for Docker container names |
| `nginx_php_default_port` | `8001` | Host port mapped to container's 8080 |
| `root_mail` | `admin@example.com` | Root email for mail aliases |
| `docker_network` | `nginx-internal` | Docker network name |
| `ssl_cert_path` | `/opt/ssl/cert.pem` | Path to SSL certificate on host |
| `ssl_key_path` | `/opt/ssl/cert.key` | Path to SSL private key on host |

### Postfix Variables (when `postfix_enabled: true`)

| Variable | Default | Description |
|----------|---------|-------------|
| `postfix_enabled` | `true` | Enable postfix mail relay |
| `postfix_relayhost` | `[smtp.example.com]:587` | SMTP relay server |
| `postfix_smtp_tls_wrappermode` | `no` | TLS wrapper mode |
| `postfix_smtp_tls_security_level` | `may` | TLS security level |
| `postfix_sasl_credentials` | *(see defaults)* | SASL auth credentials |
| `postfix_sender_email` | `server@example.com` | From address for outgoing mail |

## Usage

### 1. Add the role to your playbook

Copy (or symlink) the `ansible-deployment` directory into your Ansible roles path as e.g. `nginx-php`:

```bash
cp -r ansible-deployment /path/to/your/ansible/roles/nginx-php
```

### 2. Create your playbook

```yaml
---
- hosts: webservers
  become: yes
  roles:
    - nginx-php
```

### 3. Configure your inventory

```yaml
# host_vars/web01.yml
nginx_php_image: "ownercz/nginx-php:u24"
php_version: "8.3"

ssl_cert_path: /etc/letsencrypt/live/example.com/fullchain.pem
ssl_key_path: /etc/letsencrypt/live/example.com/privkey.pem

sites:
  - name: example.com
    port: 8005
  - name: blog.example.com
    port: 8006

postfix_enabled: true
postfix_relayhost: "[smtp.gmail.com]:587"
postfix_sasl_credentials: "[smtp.gmail.com]:587 user@gmail.com:app-password"
postfix_sender_email: "noreply@example.com"
```

### 4. Run the playbook

```bash
ansible-playbook -i inventory site.yml
```

## What the Role Does

1. **Creates directory structure** on the host under `nginx_php_base_path`
2. **Deploys docker-compose.yml** with the container configuration, port mappings, and volume mounts
3. **Generates nginx.conf** and per-site vhost configs
4. **Creates web root directories** for each site
5. **Configures postfix** (optional) as an SMTP relay inside the container using `startpost.sh`
6. **Creates the Docker network** if it doesn't exist
7. **Restarts the container** when configuration changes

## Host Directory Layout (after deployment)

```
/opt/docker/nginx-php/
├── compose/
│   ├── .env
│   ├── docker-compose.yml
│   ├── nginx.conf
│   ├── startpost.sh
│   ├── postfix-resolv.conf
│   └── sites/
│       ├── example.com.conf
│       └── blog.example.com.conf
└── data/
    ├── example.com/          # Web root for example.com
    ├── blog.example.com/     # Web root for blog.example.com
    ├── postfix/              # Postfix configuration files
    └── log/
        └── nginx/
```

## Customization

### Custom nginx vhost

Edit `templates/nginx-vhost.conf.j2` to adjust PHP-FPM settings, add WordPress rewrite rules, enable SSL termination, etc.

### Multiple containers

If you need separate containers (e.g., different postfix configs per group of sites), duplicate the role and adjust `container_name_prefix` and the docker-compose template.

### Without postfix

Set `postfix_enabled: false` in your variables. The container will run without mail relay, and the `startpost.sh` script won't be mounted.

## License

MIT
