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
check_root() {
    if [ $USERID -ne 0 ]; then
        echo -e " ${RED}You must be root to run this script.${RESET}" | tee -a $LOG_FILE
        exit 1
    fi
}

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
Mongodb_PrivateIp(){
    MONGODB_HOST=$(/usr/local/bin/aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=mongodb" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text)
    
    echo "MongoDB IP: $MONGODB_HOST"

    # Update service file
    sed -i "s|mongodb://.*:27017|mongodb://$MONGODB_HOST:27017|g" catalogue.service
}

# Installing NodeJS
Install_NodeJS(){
    dnf module disable nodejs -y &>>$LOG_FILE 
    VALIDATE $? "Disabling NodeJS"
    dnf module enable nodejs:20 -y&>>$LOG_FILE 
    VALIDATE $? "Enabling NodeJS 20"
    dnf install nodejs -y&>>$LOG_FILE
    VALIDATE $? "Installing NodeJS"
    npm install &>>$LOG_FILE 
    VALIDATE $? "Install Dependencies"
}

# App Set up
App_Setup(){
    mkdir -p /app
    VALIDATE $? "Creating app directory"

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOG_FILE 
    VALIDATE $? "Dowloading $app_name application"

    cd /app
    VALIDATE $? "Changing to app directory"

    rm -rf /app/*
    VALIDATE $? "Removing Existing Code"
    unzip /tmp/$app_name.zip &>>$LOG_FILE 
    VALIDATE $? "Unzip $app_name"
}

# Add application user
Application_User(){
    id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE 
        VALIDATE $? "Creating System User"
    else
        echo -e "User already exists! $YELLOW Skipping $RESET"

    fi
}

# Systemd setup
Systemd_Setup(){

    cp $SCRIPT_PATH/$app_name.service /etc/systemd/system/$app_name.service
    VALIDATE $? "Copy systemctl services"

    systemctl daemon-reload
    systemctl enable $app_name &>>$LOG_FILE  
    VALIDATE $? "Enable $app_name"
}
