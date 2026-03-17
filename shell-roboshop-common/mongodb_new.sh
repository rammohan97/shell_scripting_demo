#!/bin/bash

source ./common.sh

check_root

# Setup the monodb repo file...
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongo repo"

# installing mongo db 
dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb"

# Enable mongodb
systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling mongodb"

# start mongodb
systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting mongodb"

# Modifying mongod configuration file...
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote conenctions to mongodb"

# Restart mongodb services
systemctl restart mongod
VALIDATE $? "Restarted mongodb"