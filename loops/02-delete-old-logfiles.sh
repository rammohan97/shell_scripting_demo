RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

LOGS_DIR="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_DIR/${SCRIPT_NAME}.log"


mkdir -p $LOGS_DIR
echo "===== Script started executing at : $(date) ======" | tee -a $LOG_FILE

SOURCE_DIR=/home/ec2-user/logs-demo

if [ ! -d $SOURCE_DIR ]; then
    echo -e "Error Sorce Directory does not exist.."
    exit 1
fi

FILES_TO_DELETE=$(find $SOURCE_DIR -name "*.log" -type f -mtime +14)

while IFS= read -r filepath
do 
    echo "Deleting the file path $filepath"
    rm -rf $filepath
    echo "Deleted the files $filepath"
done <<< $FILES_TO_DELETE