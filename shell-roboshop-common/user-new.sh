#!/bin/bash

source ./common.sh 

app_name=user

check_root

Mongodb_PrivateIp

Redis_PrivateIp

App_Setup

Install_NodeJS

Application_User

Systemd_Setup

Restart_App

