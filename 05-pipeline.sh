#!/bin/bash

PREFIX=a-new-startup

echo "Creating simple CodePipeline pipeline (Source/Build/Deploy) ..."
aws cloudformation deploy --template-file pipeline.yaml --stack-name $PREFIX-pipeline --capabilities CAPABILITY_NAMED_IAM


