#!/bin/bash

source ./common.sh

app_name=mysql

check_root

Installing_MySQL

# Setting the password
mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "Setting the password"