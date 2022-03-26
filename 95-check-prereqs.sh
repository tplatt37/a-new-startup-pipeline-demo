#!/bin/bash

#
# This checks for various pre-requisites
#
EXIT_CODE=0

echo "Checking for pre-requisites..."

# Check AWS CLI version - must be v2.
AWS_CLI_VERSION=$(aws --version | grep -Po '(?<=aws-cli/)\d')
if [[ $AWS_CLI_VERSION -lt 2 ]]; then
    echo "You must install AWS CLI v2 to use this script."
    echo "You should probably UNINSTALL AWS CLI V1: https://docs.aws.amazon.com/cli/v1/userguide/install-linux.html#install-linux-pip"
    echo " and then "
    echo " INSTALL AWS CLI V2: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    EXIT_CODE=1
fi

if [[ EXIT_CODE -eq 0 ]]; then
    echo "No missing pre-requisites found."
else
    echo "Missing pre-requisites. Please take the suggested action."
fi

exit $EXIT_CODE
    
