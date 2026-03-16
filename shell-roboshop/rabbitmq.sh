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

# Creating rabbitmq repo
cp $SCRIPT_PATH/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "Adding Rabbitmq repo"

# Installing Rabbitmq
dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing Rabbitmq"

# Start Rabbitmq services
systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Enabling Rabbitmq"
systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Starting Rabbitmq"

# Settingup the password
rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "Settingup Permissions"