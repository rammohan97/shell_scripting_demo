#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

LOGS_DIR="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_DIR/${SCRIPT_NAME}.log"
SCRIPT_PATH=$pwd
USERID=$(id -u)

mkdir -p $LOGS_DIR
echo "===== Script started executing at : $(date) ======" | tee -a $LOG_FILE

# Check if the user is root
if [ $USERID -ne 0 ]; then
    echo -e " ${RED}You must be root to run this script.${RESET}" | tee -a $LOG_FILE
    exit 1
fi

# Create a function to check the validation of the installation process
VALIDATE() {
if [ $1 -eq 0 ]; then
    echo -e " $2 ${GREEN} Success ${RESET}" | tee -a $LOG_FILE
else
    echo -e " $2 ${RED}  Failed  ${RESET}" | tee -a $LOG_FILE
    exit 1
fi
}

# Getting mongodb PrivateIP address and updating it in catalogue.service
MONGODB_HOST=$(aws ec2 describe-instances \
--filters "Name=tag:Name,Values=mongodb" "Name=instance-state-name,Values=running" \
--query 'Reservations[*].Instances[*].PrivateIpAddress' \
--output text)

sed -i "s/<MONGODB-SERVER-IPADDRESS>/$MONGODB_HOST/g" catalogue.service
VALIDATE $? "Updating mongodb PrivateIP address in catalogue service file"


# Disabling Current module
dnf module disable nodejs -y &>>$LOG_FILE 
VALIDATE $? "Disabling NodeJS"

# Enable required module
dnf module enable nodejs:20 -y&>>$LOG_FILE 
VALIDATE $? "Enabling NodeJS 20"

# Install NodeJS
dnf install nodejs -y&>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

# Add application user
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE 
    VALIDATE $? "Creating System User"
else
    echo -e "User already exists! $YELLOW Skipping $RESET"

fi

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


# Load Master Data
mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE 
VALIDATE $? "Load Catalogue products"

# Re-start catalogue services
systemctl restart catalogue
VALIDATE $? "Restarted catalogue"
