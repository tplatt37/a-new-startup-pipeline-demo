#!/bin/bash
#
# This executes the AmazonCloudWatch-ManageAgent document against the web server instances.
# Which will result in a default CloudWatch agent config for metrics.
# CWAgent was installed via User Data.
# THere's an SSM parameter created in backend.yaml that has the config.
#
# Why don't we install this via USER DATA? Because the config file needs INSTANCE ID which is only known after the instance is created. The official examples show using cfn-init, but I don't use cfn-init in this particular project.  (For no particular reason - maybe that's a better way to do it but it's easier for students to understand "user data" before they understand all the extra baggage of metadata/cfn-init/cnf-signal, etc.)
#
# To be clear - in a REAL system , I'd configure it using cfn-init and cfn-signal.
#
# Use this to confirm agent running on EC2:
# service amazon-cloudwatch-agent status

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}
echo "Configuring CloudWatch agent for demo:a-new-startup in $REGION..."

#
# This was generated in the console UI
# This configures that agent using the configuration specified in the SSM parameter.
# (named /a-new-startup/dev/AmazonCloudWatch-AgentConfig)
#

# NOTE: If you get an error like:
# "when calling the SendCommand operation: document AmazonCloudWatch-ManageAgent does not support parameters."
# that means your parameter is BAD.   SendCommand certainly does support using --parameters!

# NOTE: we are hardcoding prefix of "a-new-startup" and "dev"
aws ssm send-command --document-name "AmazonCloudWatch-ManageAgent" --document-version "8" --targets '[{"Key":"tag:demo","Values":["a-new-startup"]}]' --parameters '{"action":["configure"],"mode":["ec2"],"optionalConfigurationSource":["ssm"],"optionalConfigurationLocation":["/a-new-startup/dev/AmazonCloudWatch-AgentConfig"],"optionalRestart":["yes"]}' --comment "No Comment" --timeout-seconds 600 --max-concurrency "50" --max-errors "0" --region $REGION