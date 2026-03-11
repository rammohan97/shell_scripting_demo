#!/bin/bash

read -p "Enter a number: " NUMBER
if [ $NUMBER -lt 10 ]; then
    echo "The number is less than 10."
elif [ $NUMBER -eq 10 ]; then
    echo "The number is equal to 10."
else
    echo "The number is greater than 10."
fi

# -gt
# -lt
# -eq
# -ne   