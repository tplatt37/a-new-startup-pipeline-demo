#!/bin/bash

#
# Run this to re-do the pipeline with a CFN deployment stage for the backend stuff.
# This results in the complete, full pipeline.
#

PREFIX=a-new-startup

echo "Creating full CodePipeline pipeline ..."
STACK_NAME=$PREFIX-pipeline
aws cloudformation deploy --template-file pipeline-full.yaml --stack-name $PREFIX-pipeline --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi
