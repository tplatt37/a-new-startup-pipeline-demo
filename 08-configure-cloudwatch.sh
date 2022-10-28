#!/bin/bash
#
# This executes the AmazonCloudWatch-ManageAgent document against the web server instances.
# Which will result in a default CloudWatch agent config for metrics.
# CWAgent was installed via User Data.
#
# Use this to confirm agent running on EC2:
# service amazon-cloudwatch-agent status

#
# This was generated in the console UI
#
aws ssm send-command --document-name "AmazonCloudWatch-ManageAgent" --document-version "7" \
--targets '[{"Key":"tag:demo","Values":["a-new-startup"]}]' \
--parameters '{"action":["configure"],"mode":["ec2"],"optionalConfigurationSource":["default"],"optionalConfigurationLocation":[""],"optionalOpenTelemetryCollectorConfigurationSource":["default"],"optionalOpenTelemetryCollectorConfigurationLocation":[""],"optionalRestart":["yes"]}' \
--timeout-seconds 600 --max-concurrency "5" --max-errors "0" 