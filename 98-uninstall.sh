#!/bin/bash

#
# This uninstalls (DELETES!) everything.
# No snapshots, nothing is retained.
#

read -p "This will delete all the a-new-startup-pipeline stacks. Are you sure? (Yy) " -n 1 -r
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

echo "OK... here we go..."

# Get the artifacts bucket from the Pipeline stack
ARTIFACT_BUCKET_STORE=$(aws cloudformation describe-stacks --stack-name a-new-startup-build-projects --query "Stacks[0].Outputs[?OutputKey=='ArtifactStoreBucket'].OutputValue" --output text )

# Empty the artifacts bucket (Otherwise stack delete will fail)
echo "Will empty bucket $ARTIFACT_BUCKET_STORE - to prevent stack delete from failing..."
aws s3 rm s3://$ARTIFACT_BUCKET_STORE --recursive

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

# .... and this one...
STACK_NAME=a-new-startup-build-projects
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME

# ... and this one
STACK_NAME=a-new-startup-backend
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=a-new-startup-repo
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME

echo "Done."
