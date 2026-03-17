#!/bin/bash

source ./common.sh

# Check the root user ot not
check_root

# Fetching MongoDB private IP
Mongodb_PrivateIp

# Disabling Current module
Current_Module

# Enable required module
Required_Module

# Install NodeJS
Install_NodeJS

# Check Application User
Application_User

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE 
VALIDATE $? "Dowloading Cataloge application"

cd /app
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing Existing Code"
unzip /tmp/catalogue.zip &>>$LOG_FILE 
VALIDATE $? "Unzip cataloge"

# npm install
npm install &>>$LOG_FILE 
VALIDATE $? "Install Dependencies"

# Processing systemctl services
cp $SCRIPT_PATH/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copy systemctl services"

# Daemon-reload
systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE  
VALIDATE $? "Enable catalogue"

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
    VALIDATE $? "Load Catalogue products"
else
    echo -e "Catalogue products already loaded!!$YELLOW Skipping $RESET"
fi

# Re-start catalogue services
systemctl restart catalogue
VALIDATE $? "Restarted catalogue"
