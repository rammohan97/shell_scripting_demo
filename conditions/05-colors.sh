#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

USERID=$(id -u)

# Create a function to check the validation of the installation process
VALIDATE() {
if [ $1 -eq 0 ]; then
    echo -e " $2 installed.... ${GREEN} Success ${RESET}"
else
    echo -e " $2 ${RED}Failed to install ${RESET}"
    exit 1
fi
}

# Check if the user is root
if [ $USERID -ne 0 ]; then
    echo -e " ${RED}You must be root to run this script.${RESET}"
    exit 1
fi

#### Installing MySQL

## Install if it is not already installed..
dnf list installed mysql
if [ $? -ne 0 ]; then
    dnf install mysql -y
    VALIDATE $? "MySQL"
else  
    echo -e " MySQL is already installed... ${YELLOW} Skipping installation ${RESET}"
fi

#### Installing Nginx

## Install if it is not already installed...
dnf list installed nginx
if [ $? -ne 0 ]; then
    dnf install nginx -y
    VALIDATE $? "Nginx"
else
    echo -e " Nginx is already installed... ${YELLOW} Skipping installation ${RESET}"
fi

#### Installing python

## Install if it is not already installed...
dnf list installed python3
if [ $? -ne 0 ]; then
    dnf install python3 -y
    VALIDATE $? "Python"
else
    echo -e " Python is already installed... ${YELLOW} Skipping installation ${RESET}"
fi
