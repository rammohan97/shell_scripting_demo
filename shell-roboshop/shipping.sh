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

# Getting Cart PrivateIP address and updating it in shipping.service
CART_HOST=$(/usr/local/bin/aws ec2 describe-instances \
--filters "Name=tag:Name,Values=cart" \
--query 'Reservations[*].Instances[*].PrivateIpAddress' \
--output text)
 
echo "CartIP: $CART_HOST"

# Update service file
sed -i "s|Environment=CART_ENDPOINT=.*:8080|Environment=CART_ENDPOINT=$CART_HOST:8080|" shipping.service

# Getting MySQL PrivateIP address and updating it in shipping.service
MYSQL_HOST=$(/usr/local/bin/aws ec2 describe-instances \
--filters "Name=tag:Name,Values=mysql" \
--query 'Reservations[*].Instances[*].PrivateIpAddress' \
--output text)
 
echo "MySQLIP: $MYSQL_HOST"

# Update service file
sed -i "s|Environment=DB_HOST=.*|Environment=DB_HOST=$MYSQL_HOST|" shipping.service


# Installing Maven
dnf install maven -y
VALIDATE $? "Installing Maven"

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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE 
VALIDATE $? "Dowloading Shipping application"

cd /app
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing Existing Code"
unzip /tmp/shipping.zip &>>$LOG_FILE 
VALIDATE $? "Unzip shipping"

# Build the application
mvn clean package &>>$LOG_FILE
VALIDATE $? "Build Success"
mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "Created JAR"

cp $SCRIPT_PATH/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copy systemctl services"

# Daemon-reload
systemctl daemon-reload 
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enable cart"
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

# Re-starting services
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restrted Shipping"