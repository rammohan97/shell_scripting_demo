#!/bin/bash

source ./common.sh

check_root

Catalogue_PrivateIp

User_PrivateIp

Cart_PrivateIp

Shipping_PrivateIp

Payment_PrivateIp

# Disabling Current Nginx module
dnf module disable nginx -y &>>$LOG_FILE 
VALIDATE $? "Disabling Nginx"

# Enable required Nginx module
dnf module enable nginx:1.24 -y &>>$LOG_FILE 
VALIDATE $? "Enabling Nginx 1.24"

# Install Nginx
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

# Start and Enable Nginx
systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enabling Nginx"
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Starting Nginx"

# Remove the default content that web server is serving
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Remove the default content that web server is serving"

# Downloading the code
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE 
VALIDATE $? "Dowloading Frontend application"

# Extract the frontend content.
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping frontend code"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Removing Existing Code"
cp $SCRIPT_PATH/nginx.conf /etc/nginx/nginx.conf

# Re-start Nginx services
systemctl restart nginx
VALIDATE $? "Restarted Nginx"
