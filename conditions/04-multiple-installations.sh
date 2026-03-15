#!/bin/bash
USERID=$(id -u)

# Create a function to check the validation of the installation process
VALIDATE() {
if [ $1 -eq 0 ]; then
    echo "$2 installed successfully."
else
    echo "Failed to install $2."
    exit 1
fi
}

# Check if the user is root
if [ $USERID -ne 0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

#### Installing MySQL
echo "Installing software..."
dnf install mysql -y
echo "Installation complete."
VALIDATE $? "MySQL"


#### Installing Nginx
echo "Installing Nginx..."
dnf install nginx -y
echo "Installation complete."
VALIDATE $? "Nginx"

#### Installing MongoDB
echo "Installing MongoDB..."
dnf install mongodb-mongosh -y
echo "Installation complete."
VALIDATE $? "MongoDB"

