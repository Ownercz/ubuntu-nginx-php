## Ubuntu docker image with Nginx and PHP  
This is a docker image for U24 that was originally forked from jdsdev/ubuntu-nginx-php:master.  
As this image is mainly used internally, if you need any changes, feel free to make a PR.  

### Usage
Services are up by supervisord, adjust it by your own needs. I use my own Ansible role that
sets up postfix, so you should include startpost.sh in your docker-compose as well.
```
      - ../startpost.sh:/opt/startpost.sh
```
#### Example docker-compose file
```
services:
  nginx-proxy:
    image: ownercz/nginx-php:u24-php8.5  
    container_name: nginx-php-{{inventory_hostname_short}}
    hostname: {{inventory_hostname_short}}
    restart: always
    user: root
    ports:
      - 8001:8080
{% for item in sites %}
      - {{ item.port }}:{{ item.port }}
{% endfor %}
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - /etc/localtime:/etc/localtime:ro
      - /usr/share/zoneinfo/UTC:/usr/share/zoneinfo/UTC:ro
      - ../startpost.sh:/opt/startpost.sh
      - /opt/docker/nginx-php/data/postfix/main.cf:/etc/postfix/main.cf
      - /opt/docker/nginx-php/data/postfix/sasl_passwd:/etc/postfix/sasl_passwd
      - /opt/docker/nginx-php/data/postfix/generic:/etc/postfix/generic
      - /opt/docker/nginx-php/data/postfix/relayhost_map:/etc/postfix/relayhost_map
      - /opt/docker/nginx-php/data/postfix/virtual:/etc/postfix/virtual
      - /opt/docker/nginx-php/data/postfix/aliases:/etc/aliases
      - /opt/docker/hosts:/etc/hosts
      - /opt/docker/hosts:/var/spool/postfix/etc/hosts
      - ../nginx.conf:/etc/nginx/nginx.conf
      - /opt/docker/nginx-php/data/log/:/var/log/
      - /opt/docker/nginx-php/data/log/nginx:/var/log/nginx
      - /opt/ssl/cert.pem:/opt/fullchain.pem
      - /opt/ssl/cert.key:/opt/privkey.pem
      - ../postfix-resolv.conf:/var/spool/postfix/etc/resolv.conf
      - ../postfix-resolv.conf:/etc/resolv.conf
{% for item in sites %}
      - ../sites/{{item.name}}.conf:/etc/nginx/conf.d/{{item.name}}.conf
      - /opt/docker/nginx-php/data/{{ item.name }}:/var/www/{{ item.name }}
{% endfor %}
    networks:
      - nginx-internal

networks:
  nginx-internal:
    external: true
    name: nginx-internal
```
#### Docker image
https://hub.docker.com/r/ownercz/nginx-php
