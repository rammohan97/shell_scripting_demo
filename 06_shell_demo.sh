#!/bin/bash

# DATE=$(date +%Y-%m-%d)

START_TIME=$(date +%s)
sleep 5
END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo "Today's date is: $DATE"
echo "Total time taken: $TOTAL_TIME seconds"