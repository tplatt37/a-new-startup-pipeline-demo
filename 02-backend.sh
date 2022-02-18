#!/bin/bash

aws cloudformation deploy --template-file backend.yaml --stack-name "a-new-startup-backend" --capabilities CAPABILITY_NAMED_IAM