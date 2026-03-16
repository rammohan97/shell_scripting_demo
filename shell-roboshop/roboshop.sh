#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0a716b1b175b22097"

# Dynamically pass the instances
for instance in $@
do
    # Create Instance and took Instance ID
    INSTANCE_ID=$(aws ec2 run-instances \
                --image-id $AMI_ID \
                --instance-type t3.micro \
                --security-group-ids $SG_ID \
                --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
                --query 'Instances[0].InstanceId' --output text)

    # Get PrivateId.
    if [ $instance == "frontend" ]; then
       IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    else
       IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    fi

    echo "$instance: $IP"

done