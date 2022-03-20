#!/bin/bash

PREFIX=a-new-startup

aws cloudformation deploy --template-file backend.yaml --stack-name "$PREFIX-backend" --capabilities CAPABILITY_IAM