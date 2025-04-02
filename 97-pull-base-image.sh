#!/bin/bash

#
# Use this to pull and push selenium/standalone-chrome from DockerHub to your own private ECR.
# This will prevent your demos from being disrupted if you get throttled by docker.io
# (and you WILL get throttled...)
#

VERSION_TAG=119.0-20250323

# Pull from docker hub.   
# NOTE: We're pinning to a version we know will work
docker pull selenium/standalone-chrome:$VERSION_TAG

# Get region from AWS_DEFAULT_REGION, or from the profile
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region)}
echo "REGION=$REGION."

# Figure out which account this is based on current identity
ACCOUNTID=$(aws sts get-caller-identity --query 'Account' | sed s/\"//g)
echo "ACCOUNTID=$ACCOUNTID."

# This is the repository we'll need to work with
REPOSITORY_URI=$ACCOUNTID.dkr.ecr.$REGION.amazonaws.com/a-new-startup-test-base-image
echo "REPOSITORY_URI=$REPOSITORY_URI."

# Must be logged into ECR - it's a private repo
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPOSITORY_URI

docker tag selenium/standalone-chrome:$VERSION_TAG $REPOSITORY_URI:latest

echo "About to push..."
docker push $REPOSITORY_URI:latest

echo "Done."