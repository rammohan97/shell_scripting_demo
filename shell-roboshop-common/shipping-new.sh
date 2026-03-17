#!/bin/bash

source ./common.sh

check_root

app_name=shipping

Cart_PrivateIp

MySQL_PrivateIp

Application_User

App_Setup

Installing_Maven

Systemd_Setup

# Starting Shipping service
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting Shipping"

# Installing MySQL
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e "show databases" | grep cities &>>$LOG_FILE
if [ $? -ne 0 ]; then
   echo "Schema not found.. loading schema"
   mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
   mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
   mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
   echo -e "Shipping data is already loaded.. $YELLOW Skipping $RESET"
fi

Restart_App


