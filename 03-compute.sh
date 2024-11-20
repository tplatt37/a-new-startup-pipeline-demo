#!/bin/bash

if [ -z $1 ]; then
        echo "Need a comma delimited list of two Public subnet Ids. Exiting..."
        exit 0
fi

# Optional - IP address to allowlist for access to the app.  if not provided, we use current IP
if [ ! -z $2 ]; then
        MY_IP=$2
else
        MY_IP=$(curl -s checkip.amazonaws.com)
fi
echo "My IP=$MY_IP"

# Optional - a DomainName and HostedZoneId as 3rd and 4th parameters
if [ ! -z $3 ]; then
        DOMAIN_NAME=$3
else
        DOMAIN_NAME="None"
fi

if [ ! -z $4 ]; then
        HOSTED_ZONE_ID=$4
else
        HOSTED_ZONE_ID="None"
fi

PREFIX=a-new-startup

# Sometimes we need a comma delimited list of subnets, other times, space delimited. 
# use $1 for the comma delimited, and SUBNETS for the space delimited.
# Subnets are needed for the ALB.
SUBNETS=$(echo $1 | sed 's/,/ /g')
echo "Subnets=$SUBNETS"
echo "DOMAIN_NAME=$DOMAIN_NAME"
echo "HOSTED_ZONE_ID=$HOSTED_ZONE_ID"

# Grab the VpcId off the first subnet. This is needed for the Security Group and Target Group.
VPC_ID=$(aws ec2 describe-subnets --subnet-ids $SUBNETS --query 'Subnets[0].VpcId' --output text)
echo "VpcId=$VPC_ID"


aws cloudformation deploy --template-file compute.yaml \
        --stack-name "$PREFIX-compute" \
        --parameter-overrides VpcId=$VPC_ID Subnets=$1 IpRangeForAccess=$MY_IP DomainName=$DOMAIN_NAME HostedZoneId=$HOSTED_ZONE_ID \
        --capabilities CAPABILITY_NAMED_IAM