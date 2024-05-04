#!/bin/bash

# Start supervisord and services
exec /usr/local/bin/supervisord -n -c /etc/supervisord.conf
