#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

LOGS_DIR="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_DIR/${SCRIPT_NAME}.log"
SCRIPT_PATH=$PWD
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
CATALOGUE_HOST=$(/usr/local/bin/aws ec2 describe-instances \
--filters "Name=tag:Name,Values=catalogue" \
--query 'Reservations[*].Instances[*].PrivateIpAddress' \
--output text)
 
echo "Catalogue IP: $CATALOGUE_HOST"
 
# Update service file
sed -i "s|Environment=CATALOGUE_HOST=.*|Environment=CATALOGUE_HOST=$CATALOGUE_HOST|" cart.service

# Getting redis PrivateIP address and updating it in cart.service
REDIS_HOST=$(/usr/local/bin/aws ec2 describe-instances \
--filters "Name=tag:Name,Values=redis" \
--query 'Reservations[*].Instances[*].PrivateIpAddress' \
--output text)

echo "RedIS IP: $REDIS_HOST"

# Update service file
sed -i "s|Environment=REDIS_HOST=.*|Environment=REDIS_HOST=$REDIS_HOST|" cart.service

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

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE 
VALIDATE $? "Dowloading Cart application"

cd /app
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing Existing Code"
unzip /tmp/cart.zip &>>$LOG_FILE 
VALIDATE $? "Unzip cart"

# npm install
npm install &>>$LOG_FILE 
VALIDATE $? "Install Dependencies"

# Processing systemctl services
cp $SCRIPT_PATH/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "Copy systemctl services"

# Daemon-reload
systemctl daemon-reload
systemctl enable cart &>>$LOG_FILE  
VALIDATE $? "Enable cart"

# Start cart services
systemctl start cart &>>$LOG_FILE
VALIDATE $? "Started cart"
