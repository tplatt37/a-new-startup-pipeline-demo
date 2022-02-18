#!/bin/bash

echo "Creating CodeBuild projects and other supporting resources ..."
aws cloudformation deploy --template-file build-projects.yaml --stack-name a-new-startup-build-projects --capabilities CAPABILITY_NAMED_IAM


