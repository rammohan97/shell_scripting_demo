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

# $@  --> Giving all the arguments passed to the function as a single string

for package in $@;
do
    # check if package is already installed or not
    dnf list installed $package &>>$LOG_FILE

    # If exist status code is 0 then it is already installed
    if [ $? -ne 0 ]; then
        dnf install $package -y &>>$LOG_FILE
        VALIDATE $? $package
    else
        echo -e "$package is already installed.... ${YELLOW} Skipping ${RESET}" | tee -a $LOG_FILE
    fi
done