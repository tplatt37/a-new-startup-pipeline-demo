#!/bin/bash

#
# Run this to re-do the pipeline with a CFN deployment stage for the backend stuff.
# This results in the complete, full pipeline.
#

PREFIX=a-new-startup

echo "Creating full CodePipeline pipeline ..."
aws cloudformation deploy --template-file pipeline-full.yaml --stack-name $PREFIX-pipeline --capabilities CAPABILITY_NAMED_IAM



 