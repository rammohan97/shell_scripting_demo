#!/bin/bash

source ./common.sh

app_name=catalogue

# Check the root user ot not
check_root

# Fetching MongoDB private IP
Mongodb_PrivateIp

# App Setup
App_Setup

# Installing NodeJS
Install_NodeJS

# Check Application User
Application_User

# systemd setup
Systemd_Setup

# Copying mongo repo
cp $SCRIPT_PATH/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"

# Installing mongodb
dnf install mongodb-mongosh -y &>>$LOG_FILE 
VALIDATE $? "Install mongodb client"

# Check the database
INDEX=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
# Load Master Data
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE 
    VALIDATE $? "Load $app_name products"
else
    echo -e "$app_name products already loaded!! $YELLOW Skipping $RESET"
fi

# Re-start catalogue services
Restart_App
