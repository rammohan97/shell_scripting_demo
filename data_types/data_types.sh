#!/bin/bash

NUM1=100
NUM2=200
NAME="John Doe"

#SUM=$(($NUM1 + $NUM2 + $NAME)) # This will cause an error because NAME is not a number

echo "The sum of $NUM1 and $NUM2 is: ${SUM}"

PEOPLE=("John" "Jane" "Bob")
echo "The persons in the array is: ${PEOPLE[@]}"
echo "The first person in the array is: ${PEOPLE[0]}"
