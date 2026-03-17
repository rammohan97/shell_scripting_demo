#!/bin/bash

source ./common.sh

app_name=rabbitmq

check_root

# Creating rabbitmq repo
cp $SCRIPT_PATH/$app_name.repo /etc/yum.repos.d/$app_name.repo &>>$LOG_FILE
VALIDATE $? "Adding $app_name repo"

Installing_Rabbitmq

# Settingup the password
rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "Settingup Permissions"

