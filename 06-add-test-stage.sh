#!/bin/bash

#
# Run this to re-do the pipeline to use the containerized testing code.
# The pipeline will take longer to run, and will be more complicated.
#

PREFIX=a-new-startup
 
echo "Creating complex CodePipeline pipeline (Source/Build App/Build Test Container/Deploy/Test) ..."
STACK_NAME=$PREFIX-pipeline
aws cloudformation deploy --template-file pipeline-with-tests.yaml --stack-name $STACK_NAME --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-exists --stack-name $STACK_NAME
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].StackStatus" --output text)
if [[ $STACK_STATUS != "CREATE_COMPLETE" ]] && [[ $STACK_STATUS != "UPDATE_COMPLETE" ]]; then
        echo "Create or Update of Stack $STACK_NAME failed: $STACK_STATUS.  Cannot continue..."
        exit 1
fi
