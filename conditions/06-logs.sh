#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

LOGS_DIR="/var/log/shell-demo"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_DIR/${SCRIPT_NAME}.log"
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
    echo -e " $2 installed.... ${GREEN} Success ${RESET}" | tee -a $LOG_FILE
else
    echo -e " $2 ${RED}Failed to install ${RESET}" | tee -a $LOG_FILE
    exit 1
fi
}

#### Installing MySQL

## Install if it is not already installed..
dnf list installed mysql &>>$LOG_FILE
if [ $? -ne 0 ]; then
    dnf install mysql -y &>>$LOG_FILE
    VALIDATE $? "MySQL"
else  
    echo -e " MySQL is already installed... ${YELLOW} Skipping installation ${RESET}" | tee -a $LOG_FILE
fi

#### Installing Nginx

## Install if it is not already installed...
dnf list installed nginx &>>$LOG_FILE
if [ $? -ne 0 ]; then
    dnf install nginx -y &>>$LOG_FILE
    VALIDATE $? "Nginx"
else
    echo -e " Nginx is already installed... ${YELLOW} Skipping installation ${RESET}" | tee -a $LOG_FILE
fi

#### Installing python

## Install if it is not already installed...
dnf list installed python3  &>>$LOG_FILE
if [ $? -ne 0 ]; then
    dnf install python3 -y &>>$LOG_FILE
    VALIDATE $? "Python"
else
    echo -e " Python is already installed... ${YELLOW} Skipping installation ${RESET}" | tee -a $LOG_FILE
fi


