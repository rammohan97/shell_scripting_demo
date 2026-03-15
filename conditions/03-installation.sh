#!/bin/bash

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

echo "Installing software..."
# Simulate installation process
dnf install mysql -y
echo "Installation complete."

if [ $? -eq 0 ]; then
    echo "MySQL installed successfully."
else
    echo "Failed to install MySQL."
    exit 1
fi