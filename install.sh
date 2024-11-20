#!/bin/bash
#
# This will run each CloudFormation template in order
# You must pass in:
#  a private S3 bucket that can be used to temporarily house the application source code ZIP file.
#  a comma delimited list of 2 Public subnets, to use for the ALB and ASG. They need to be in the same VPC, of course!
#
# Example:
# ./install.sh temp-bucket-3938abfg subnet-01394a2a0668b9de3,subnet-0696d8146ac458a3d
#
# OPTIONAL: You can also specify a Domain Name (for an already existing Hosted Zone in Route 53) as follows:
# ./install.sh temp-bucket-3938abfg subnet-01394a2a0668b9de3,subnet-0696d8146ac458a3d app.example.com Z10426613LMJT7YG1WWWW
#
# In the above, example.com must be an existing Hosted Zone.
#
#

# Check for pre-requisites
./95-check-prereqs.sh
if [[ $? -ne 0 ]]; then
    echo "Missing prerequisites... exiting..."
    exit 1
fi

# Used in naming some of the cfn Exports.
PREFIX=a-new-startup

# Must pass in an s3 bucket (private) where the source code zip can be stored...
if [ -z $1 ]; then
        echo "Need the S3 Bucket Name as a parameter. Exiting..."
        echo "Use is: ./install.sh BUCKET_NAME COMMA_DELIMITED_LIST_PUBLIC_SUBNETS DOMAIN_NAME HOSTED_ZONE_ID"
        echo "DOMAIN_NAME and HOSTED_ZONE_ID are optional"
        exit 0
fi
BUCKET=$1

if [ -z $2 ]; then
        echo "Also need a comma delimited list of two Public subnet Ids. Exiting..."
        echo "Use is: ./install.sh BUCKET_NAME COMMA_DELIMITED_LIST_PUBLIC_SUBNETS DOMAIN_NAME HOSTED_ZONE_ID"
        echo "DOMAIN_NAME and HOSTED_ZONE_ID are optional"
        exit 0
fi
SUBNETS_COMMADELIMITED=$2

# Optional - IP address to allowlist for access to the app.  if not provided, we use current IP
if [ ! -z $3 ]; then
        MY_IP=$3
else
        MY_IP=$(curl -s checkip.amazonaws.com)
fi
echo "MY_IP=$MY_IP"

#
# DomainName and HostedZoneId are OPTIONAL
# If you supply these, a custom domain name and HTTPS/443 will be used.
# The Domain MUST already exist in Route 53 as a Hosted Zone.
# For example, if you want to use app.example.com, example.com must be a Hosted Zone.
#
if [ ! -z $4 -a -z $5 ]; then
        echo "If you specify a DomainName you must also specify the HostedZoneId"
        exit 0
fi

if [ ! -z $4 ]; then
        DOMAIN_NAME=$4
else
        DOMAIN_NAME=""
fi

if [ ! -z $5 ]; then
        HOSTED_ZONE_ID=$5
else
        HOSTED_ZONE_ID=""
fi

echo "DOMAIN_NAME=$DOMAIN_NAME"
echo "HOSTED_ZONE_ID=$HOSTED_ZONE_ID"

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}
echo "Creating in $REGION..."

echo "Validating VPC and Subnets..."
SUBNETS=$(echo $SUBNETS_COMMADELIMITED | sed 's/,/ /g')
echo "Subnets=$SUBNETS."

aws ec2 describe-subnets --subnet-ids $SUBNETS 1>/dev/null
if [[ $? -ne 0 ]]; then
        echo "Subnets $SUBNETS don't exist ($REGION) - please double check.  Exiting..."
        exit 1
fi

# Grab the VpcId off the first subnet. This is needed for the Security Group and Target Group.
VPC_ID=$(aws ec2 describe-subnets --subnet-ids $SUBNETS --query 'Subnets[0].VpcId' --output text)
echo "VpcId=$VPC_ID."

echo "Copying ZIP to $BUCKET, and creating CodeCommit repo..."
./01-repo.sh $BUCKET

STACK_NAME=$PREFIX-repo
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi

echo "Creating backend infra ..."
STACK_NAME=$PREFIX-backend
./02-backend.sh 
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi

echo "Creating compute layer..."
STACK_NAME=$PREFIX-compute
if [ ! -z $DOMAIN_NAME ]; then
        ./03-compute.sh $SUBNETS_COMMADELIMITED $MY_IP $DOMAIN_NAME $HOSTED_ZONE_ID
else
        ./03-compute.sh $SUBNETS_COMMADELIMITED $MY_IP
fi
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi

echo "Creating Build Projects..."
STACK_NAME=$PREFIX-build-projects
./04-build-projects.sh
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi

echo "Creating Pipeline..." 
STACK_NAME=$PREFIX-pipeline
./05-pipeline.sh
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi

echo "Done..."

PROTOCOL=$(aws cloudformation describe-stacks --stack-name a-new-startup-compute --query "Stacks[0].Outputs[?OutputKey=='Protocol'].OutputValue" --output text )
DNSNAME=$(aws cloudformation describe-stacks --stack-name a-new-startup-compute --query "Stacks[0].Outputs[?OutputKey=='ALBDNS'].OutputValue" --output text )

echo "Open this URL in your browser to see the app. NOTE: It won't work until the first run of the Pipeline finishes...give it a few minutes."
echo " "
if [ $PROTOCOL == "https" ]; then
        echo "$PROTOCOL://$DOMAIN_NAME"
else
        echo "$PROTOCOL://$DNSNAME"
fi
echo " "
