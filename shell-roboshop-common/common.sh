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

# Getting mongodb PrivateIP address and updating it service file
Mongodb_PrivateIp(){
    MONGODB_HOST=$(/usr/local/bin/aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=mongodb" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text)
    
    echo "MongoDB IP: $MONGODB_HOST"

    # Update service file
    sed -i "s|mongodb://.*:27017|mongodb://$MONGODB_HOST:27017|g" $app_name.service
}

# Getting redis PrivateIP address and updating it in service file
Redis_PrivateIp(){
    REDIS_HOST=$(/usr/local/bin/aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=redis" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text)

    echo "RedIS IP: $REDIS_HOST"

    # Update service file
    sed -i "s|redis://.*:6379|redis://$REDIS_HOST:6379|g" $app_name.service
    
    # Update in cart.service
    sed -i "s|Environment=REDIS_HOST=.*|Environment=REDIS_HOST=$REDIS_HOST|" cart.service
}

# Getting Cart PrivateIP address and updating it in service file
Cart_PrivateIp(){
    CART_HOST=$(/usr/local/bin/aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=cart" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text)
    
    echo "CartIP: $CART_HOST"

    # Update service file
    sed -i "s|Environment=CART_ENDPOINT=.*|Environment=CART_ENDPOINT=${CART_HOST}:8080|g" $app_name.service
}

# Getting MySQL PrivateIP address and updating it in service file
MySQL_PrivateIp(){
    MYSQL_HOST=$(/usr/local/bin/aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=mysql" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text)
    
    echo "MySQLIP: $MYSQL_HOST"

    # Update service file
    sed -i "s|Environment=DB_HOST=.*|Environment=DB_HOST=$MYSQL_HOST|" shipping.service
}

# Getting catalouge PrivateIP address and updating it in service file
Catalogue_PrivateIp(){
    CATALOGUE_HOST=$(/usr/local/bin/aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=catalogue" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text)
    
    echo "Catalogue IP: $CATALOGUE_HOST"
    
    # Update service file
    sed -i "s|Environment=CATALOGUE_HOST=.*|Environment=CATALOGUE_HOST=$CATALOGUE_HOST|" $app_name.service

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

# Installing Redis
Installing_Redis(){

    # Disable module redis
    dnf module disable redis -y &>>$LOG_FILE
    VALIDATE $? "Disabling default module redis"

    # Enabling redis
    dnf module enable redis -y &>>$LOG_FILE
    VALIDATE $? "Enabling redis"

    # Install redis
    dnf install redis -y &>>$LOG_FILE
    VALIDATE $? "Installing redis"
}

# Installing Maven
Installing_Maven(){
    dnf install maven -y
    VALIDATE $? "Installing Maven"
    mvn clean package &>>$LOG_FILE
    VALIDATE $? "Build Success"
    mv target/$app_name-1.0.jar $app_name.jar
    VALIDATE $? "Created JAR"
}

# Installing MySQL Server
Installing_MySQL(){
    dnf install mysql-server -y &>>$LOG_FILE
    VALIDATE $? "Installing $app_name server"
    systemctl enable mysqld &>>$LOG_FILE
    VALIDATE $? "Enabling $app_name server"
    systemctl start mysqld &>>$LOG_FILE
    VALIDATE $? "Start $app_name server"
}

# Installing Rabbitmq
Installing_Rabbitmq(){
    dnf install rabbitmq-server -y &>>$LOG_FILE
    VALIDATE $? "Installing $app_name"
    systemctl enable rabbitmq-server &>>$LOG_FILE
    VALIDATE $? "Enabling $app_name"
    systemctl start rabbitmq-server &>>$LOG_FILE
    VALIDATE $? "Starting $app_name"
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

# Restart App
Restart_App(){

    systemctl restart $app_name
    VALIDATE $? "Restarted $app_name"
}