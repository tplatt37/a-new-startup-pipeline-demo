#!/bin/bash

PREFIX=a-new-startup

echo "Creating CodeBuild projects and other supporting resources ..."
aws cloudformation deploy --template-file build-projects.yaml --stack-name $PREFIX-build-projects --capabilities CAPABILITY_NAMED_IAM


