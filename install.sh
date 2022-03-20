#!/bin/bash
#
# This will run each CloudFormation template in order
# You must pass in:
#  a private S3 bucket that can be used to temporarily house the application source code ZIP file.
#  a comma delimited list of 2 Public subnets, to use for the ALB and ASG. They need to be in the same VPC, of course!
#
# Example:
# ./00-install.sh temp-bucket-3938abfg subnet-01394a2a0668b9de3,subnet-0696d8146ac458a3d
#
#

# Used in naming some of the cfn Exports.
PREFIX=a-new-startup

# Must pass in an s3 bucket (private) where the source code zip can be stored...
if [ -z $1 ]; then
        echo "Need the S3 Bucket Name as a parameter. Exiting..."
        exit 0
fi
BUCKET=$1

if [ -z $2 ]; then
        echo "Also need a comma delimited list of two Public subnet Ids. Exiting..."
        exit 0
fi
SUBNETS_COMMADELIMITED=$2

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
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi


echo "Creating backend infra ..."
STACK_NAME=$PREFIX-backend
./02-backend.sh 
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi

exit 0


echo "Creating compute layer..."
./03-compute.sh $SUBNETS_COMMADELIMITED

aws cloudformation wait stack-create-complete --stack-name "a-new-startup-compute"

echo "Creating Build Projects..."
./04-build-projects.sh

aws cloudformation wait stack-create-complete --stack-name "a-new-startup-pipeline"

echo "Creating Pipeline..." 
./05-pipeline.sh

echo "Done..."

DNSNAME=$(aws cloudformation describe-stacks --stack-name a-new-startup-compute --query "Stacks[0].Outputs[?OutputKey=='ALBDNS'].OutputValue" --output text )
echo "Open this URL in your browser to see the app. NOTE: It won't work until the first run of the Pipeline finishes...give it a few minutes."
echo " "
echo "http://$DNSNAME"
echo " "
