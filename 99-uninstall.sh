#!/bin/bash

#
# This uninstalls (DELETES!) everything.
# No snapshots, nothing is retained.
#

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}

# NOTE: if you invoke with --yes it will skip these "Are you sure?" prompts
if [[ -z $1 || $1 != "--yes" ]]; then
    read -p "This will delete all the a-new-startup-pipeline stacks in $REGION. Are you sure? (Yy) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
    
    read -p "Are you sure you are sure???? (Yy) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
fi

echo "OK... here we go..."

# Get the artifacts bucket from the Pipeline stack
ARTIFACT_BUCKET_STORE=$(aws cloudformation describe-stacks --stack-name a-new-startup-build-projects --query "Stacks[0].Outputs[?OutputKey=='ArtifactStoreBucket'].OutputValue" --output text )
echo "ARTIFACT_BUCKET_STORE=$ARTIFACT_BUCKET_STORE."

# Empty the artifacts bucket (Otherwise stack delete will fail)
echo "Will empty bucket $ARTIFACT_BUCKET_STORE - to prevent stack delete from failing..."
aws s3 rm s3://$ARTIFACT_BUCKET_STORE --recursive

# Get the logging bucket from the Repo stack
LOGGING_BUCKET=$(aws cloudformation describe-stacks --stack-name a-new-startup-repo --query "Stacks[0].Outputs[?OutputKey=='LoggingBucket'].OutputValue" --output text )
echo "LOGGING_BUCKET=$LOGGING_BUCKET."

# Empty the artifacts bucket (Otherwise stack delete will fail)
echo "Will empty bucket $LOGGING_BUCKET - to prevent stack delete from failing..."
aws s3 rm s3://$LOGGING_BUCKET --recursive

# Manually --force delete the ecr repos.  They'll fail to delete otherwise.
aws ecr delete-repository --repository-name "a-new-startup-test-base-image" --force
aws ecr delete-repository --repository-name "a-new-startup-testing-image" --force

# Gotta delete this one first, and wait for it.
STACK_NAME=a-new-startup-pipeline
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

# Also this one...
STACK_NAME=a-new-startup-compute
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

# ... and this one
STACK_NAME=a-new-startup-backend
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

# .... and this one...
STACK_NAME=a-new-startup-build-projects
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=a-new-startup-repo
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

echo "Done."
