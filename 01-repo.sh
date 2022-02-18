#!/bin/bash
# Must pass in the bucket name you want to use.

# Must pass in an s3 bucket (private) where the source code zip can be stored...
if [ -z $1 ]; then
        echo "Need the S3 Bucket Name as a parameter. Exiting..."
        exit 0
fi

echo "Copying application source zip to S3 bucket"
#
# This is a zip of the application source code, used to initialize the app code repo.
aws s3 cp a-new-startup.zip s3://$1

# This is a zip of the testing code (python/selenim) used to test the UI.
aws s3 cp a-new-startup-ui-tests.zip s3://$1

echo "Setting up CodeCommit repos and ECR repos..."
aws cloudformation deploy --template-file repo.yaml --stack-name a-new-startup-repo --parameter-overrides CodeBucketName=$1

echo "Waiting for stack update"

#
# Now that our ECR repo is there, pull and push the selenium/standalone-chrome image
# This prevents our demo from getting failures to due to docker.io throttling.
#
source ./97-pull-base-image.sh

