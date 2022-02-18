#!/bin/bash

 #
 # Run this to re-do the pipeline to use the containerized testing code.
 # The pipeline will take longer to run, and will be more complicated.
 #
echo "Creating complex CodePipeline pipeline (Source/Build App/Build Test Container/Deploy/Test) ..."
aws cloudformation deploy --template-file pipeline-with-tests.yaml --stack-name a-new-startup-pipeline --capabilities CAPABILITY_NAMED_IAM



 