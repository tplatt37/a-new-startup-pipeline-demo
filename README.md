# Overview

These CloudFormation templates create an EC2/ASG/ALB dev environment for the A-New-Startup application, and a complete CI/CD pipeline.

This set of templates will create resources that cost money - including some with billing per hour (EC2 instances, Application Load Balancer, etc.)

The A-New-Startup application source code will be placed into a CodeCommit repo.
Next, an Application Load Balancer with an Auto Scaling Group and Target Group will be created.
A Launch Template is used in conjunction with an ASG.  
The Launch Template specifies a few minor things, including a User Data to install the CodeDeploy agent.
A Pipeline uses CodePipeline/CodeBuild/CodeDeploy to deploy the A-New-Startup application to the instances in the ASG.

# Requirements

You need to supply a VPC with 2 Public Subnets.  If you are going to continue beyond this demo with the ECS demo, choose a VPC with both Public and Private subnets.  The Private subnets would be needed for the ECS (Fargate) demo later.

You need to supply a private S3 bucket, which will be used to temporarily house the A-New-Startup source code (so it can be copied into the CodeCommit repo.)

This set of templates uses many static/fixed resource names (stack names, repo name, iam stuff, and much more) for simplicity's sake. 
This means you can only install it ONCE per account (stack will fail with naming conflicts otherwiwse).
If you need multiple installs, use different accounts!

This repo is meant for demos to students - so we keep it as simple (as possible).

# Installation

I recommend setting your AWS_DEFAULT_REGION first:

export AWS_DEFAULT_REGION=us-east-1

Run the following command, and pass the S3 Bucket Name as the first argument, and a comma delimited list of the 2 PUBLIC subnets:

./00-install.sh "BUCKET_NAME_HERE" "subnet-1234568999,subnet-8298392925"

Alternatively, you can run the individual files (This is helpful after the initial install if you are making updates and only want one stack to be updated.)

./01-repo.sh "BUCKET_NAME_HERE"

./02-backend.sh

./03-compute.sh "subnet-1234568999,subnet-8298392925"

./04-build-projects.sh

./05-pipeline.sh

# What's Next?

The pipeline will kick off automatically after you install it.  Navigate to CodePipeline to see it in action.  

After it is deployed, pull up the ALB DNSName in your browser to see the app. (The DNSName is an output of a-new-startup-compute stack - for convenience)

To run it again, you have the option of using "Release Change" in CodePipeline, or cloning the application source, and making changes.

Find the Clone URL using:
aws codecommit get-repository --repository-name "a-new-startup"

or

aws codecommit get-repository --repository-name "a-new-startup" --query "repositoryMetadata.cloneUrlSsh"

Then run a git clone:
git clone ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/a-new-startup

or use command substitution to do all that in one command (NOTE: Using ssh here.  Change to http if desired)

git clone $(aws codecommit get-repository --repository-name "a-new-startup" --query "repositoryMetadata.cloneUrlSsh" --output text)         

Modify some of the visible text in src/views/index.ejs (for an easy and visible change)

git commit -a -m "updated version number"

git push

The pipeline should then kick off with the latest commit.

# Then what? 

There's an option on the pipeline stack to include a testing stage.

This stage uses a containerized python script with Selenium to perform a UI level test of the code.

Enable this stage by running:

./06-add-test-stage.sh

Please note that this version of the pipeline will take longer to run, and it will be more complicated.

(Which is why this extra stage isn't included at first)


# Uninstall

To uninstall (WARNING - This deletes EVERYTHING created above - no snapshots, no retain - even on the DynamoDB table)

./98-uninstall.sh 

To uninstall manually:
1. Empty the ArtifactStoreBucket (Look for an output in the a-new-startup-pipeline stack created by pipeline.yaml)
2. Empty the two ECR repos
3. Delete the CloudFormation stacks (There will be four, all named as a-new-startup-* 
3. Delete the a-new-startup.zip and a-new-startup-ui-tests.zip files from your private S3 bucket.

# Other things...

The a-new-startup.zip file is a zip of the application source code. It includes the files needed for the CI/CD pipeline (buildspec.yaml, appspec.yaml)

You don't need 99-zip-source-bundle.sh.  That's a utility file for the maintainer (me).

The a-new-startup-ui-tests.zip is the simple code to perform the Selenium testing.

97-pull-base-image.sh is called by another shell file to "cache" the Selenium/Headless Chrome image in a private ECR repo. 

If you attempt to pull that particular container image from docker.io - you WILL get throttled at random times - and that's not good for demos!

# A Warning

This code should NOT be considered production ready.  
While some best practices have been incorporated, the primary goal was to keep things SIMPLE so that students can absorb what they are being shown - without tons of extraneous error checking and complicated dynamic names.



