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

# Must pass in an s3 bucket (private) where the source code zip can be stored...
if [ -z $1 ]; then
        echo "Need the S3 Bucket Name as a parameter. Exiting..."
        exit 0
fi

if [ -z $2 ]; then
        echo "Need a comma delimited list of two Public subnet Ids. Exiting..."
        exit 0
fi


echo "Copying ZIP to $1, and creating CodeCommit repo..."
source 01-repo.sh $1

aws cloudformation wait stack-create-complete --stack-name "a-new-startup-repo"

echo "Creating backend infra ..."
source 02-backend.sh 

aws cloudformation wait stack-create-complete --stack-name "a-new-startup-backend"

echo "Creating compute layer..."
source 03-compute.sh $2

aws cloudformation wait stack-create-complete --stack-name "a-new-startup-compute"

echo "Creating Build Projects..."
source 04-build-projects.sh

aws cloudformation wait stack-create-complete --stack-name "a-new-startup-pipeline"

echo "Creating Pipeline..." 
source 05-pipeline.sh

echo "Done..."

DNSNAME=$(aws cloudformation describe-stacks --stack-name a-new-startup-compute --query "Stacks[0].Outputs[?OutputKey=='ALBDNS'].OutputValue" --output text )
echo "Open this URL in your browser to see the app:"
echo "http://$DNSNAME"

