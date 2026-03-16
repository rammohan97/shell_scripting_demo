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

# Getting Cart PrivateIP address and updating it in payment.service
CART_HOST=$(/usr/local/bin/aws ec2 describe-instances \
--filters "Name=tag:Name,Values=cart" \
--query 'Reservations[*].Instances[*].PrivateIpAddress' \
--output text)
 
echo "CartIP: $CART_HOST"

# Update service file
sed -i "s|Environment=CART_HOST=.*|Environment=CART_HOST=$CART_HOST|" payment.service

# Getting User PrivateIP address and updating it in payment.service
USER_HOST=$(/usr/local/bin/aws ec2 describe-instances \
--filters "Name=tag:Name,Values=user" \
--query 'Reservations[*].Instances[*].PrivateIpAddress' \
--output text)
 
echo "USER_IP: $USER_HOST"

# Update service file
sed -i "s|Environment=USER_HOST=.*|Environment=USER_HOST=$USER_HOST|" payment.service

# Getting Rabbitmq PrivateIP address and updating it in payment.service
RABBITMQ_HOST=$(/usr/local/bin/aws ec2 describe-instances \
--filters "Name=tag:Name,Values=rabbitmq" \
--query 'Reservations[*].Instances[*].PrivateIpAddress' \
--output text)
 
echo "RABBITMQ_IP: $RABBITMQ_HOST"

# Update service file
sed -i "s|Environment=AMQP_HOST=.*|Environment=AMQP_HOST=$RABBITMQ_HOST|" payment.service

# Installing python3
dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing Python3"

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

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE 
VALIDATE $? "Dowloading payment application"

cd /app
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing Existing Code"
unzip /tmp/payment.zip &>>$LOG_FILE 
VALIDATE $? "Unzip payment"

# Downloading Dependencies
pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Downloaded Dependencies"

cp $SCRIPT_PATH/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "Copy systemctl services"

# Daemon-reload
systemctl daemon-reload 
systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Enable payment"

# Re-starting services
systemctl restart payment &>>$LOG_FILE
VALIDATE $? "Restrted payment"