#!/bin/bash
#
# You probably don't need to run this.
# This is a helper script for the demo maintainer

# Assuming you have a-new-startup code one dir level up, zip it up in a way that we can use to 
# initialize the CodeCommit Repo for the demo.
# We need the .jest hidden folder, but not .git
# also note. this needs to be a-new-starutp with ALL the files - buildspec.yaml, etc.

# To setup for this, run the following
# git clone git@github.com:tplatt37/a-new-startup.git a-new-startup-github
# git clone $(aws codecommit get-repository --repository-name "a-new-startup-ui-tests" --query "repositoryMetadata.cloneUrlSsh" --output text) 
#
# Make file changes as needed...
#
# Then run this bash script.
#

# This is the application code.
cd ../a-new-startup-github && zip -r --exclude=*.git/* ../a-new-startup-pipeline-demo/a-new-startup.zip ./* .[^.]* && cd ../a-new-startup-pipeline-demo

# This is the testing code, which lives in a different repo
cd ../a-new-startup-ui-tests && zip -r --exclude=*.git/* --exclude=*.zip --exclude=*.sh ../a-new-startup-pipeline-demo/a-new-startup-ui-tests.zip ./* .[^.]* && cd ../a-new-startup-pipeline-demo

