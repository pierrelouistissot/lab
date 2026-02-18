#!/bin/bash
set -e

service cron start
exec /usr/sbin/sshd -D
