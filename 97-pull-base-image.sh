#!/bin/bash

#
# Use this to pull and push selenium/standalone-chrome from DockerHub to your own private ECR.
# This will prevent your demos from being disrupted if you get throllted by docker.io
# (and you WILL get throttled...)
#

# Pull from docker hub
docker pull selenium/standalone-chrome

# Get region from AWS_DEFAULT_REGION, or from the profile
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region)}

# Figure out which account this is based on current identity
ACCOUNTID=$(aws sts get-caller-identity --query 'Account' | sed s/\"//g)

# This is the repository we'll need to work with
REPOSITORY_URI=$ACCOUNTID.dkr.ecr.$REGION.amazonaws.com/a-new-startup-test-base-image

echo $REPOSITORY_URI

# Must be logged into ECR - it's a private repo
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPOSITORY_URI

docker tag selenium/standalone-chrome $REPOSITORY_URI:latest

docker push $REPOSITORY_URI:latest

