#!/bin/bash

source ./common.sh

app_name=redis

check_root

Installing_Redis

# Update listen address
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing Remote Connections to redis"

Restart_App

