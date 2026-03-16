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

# Getting catalogue PrivateIP address and updating it in nginx.conf
CATALOGUE_HOST=$(/usr/local/bin/aws ec2 describe-instances \
--filters "Name=tag:Name,Values=catalogue" \
--query 'Reservations[*].Instances[*].PrivateIpAddress' \
--output text)
 
echo "Catalogue IP: $CATALOGUE_HOST"
 
# Update service file
sed -i "/location \/api\/catalogue/ s|http://.*:8080|http://$CATALOGUE_HOST:8080|g" nginx.conf

# Getting User PrivateIP address and updating it in nginx.conf
USER_HOST=$(/usr/local/bin/aws ec2 describe-instances \
--filters "Name=tag:Name,Values=user" \
--query 'Reservations[*].Instances[*].PrivateIpAddress' \
--output text)
 
echo "User IP: $USER_HOST"
 
# Update service file
sed -i "/location \/api\/user/ s|http://.*:8080|http://$USER_HOST:8080|g" nginx.conf


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
