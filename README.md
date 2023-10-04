# Overview

These CloudFormation templates create an EC2/ASG/ALB dev environment for the A-New-Startup application, and a complete CI/CD pipeline.

This set of templates will create resources that cost money - including some with billing per hour (EC2 instances, Application Load Balancer, etc.)

The A-New-Startup application source code will be placed into a CodeCommit repo.
Next, an Application Load Balancer with an Auto Scaling Group and Target Group will be created.
A Launch Template is used in conjunction with an ASG.  
The Launch Template specifies a few minor things, including a User Data to install the CodeDeploy agent.
A Pipeline uses CodePipeline/CodeBuild/CodeDeploy to deploy the A-New-Startup application to the instances in the ASG.

This codebase is meant for the DevOps Engineering on AWS class.  As such, it follows a simple "script" and keeps things simple.

# Requirements

You need to supply a VPC with 2 Public Subnets (EC2 instances must default to be assigned a Public IP!).  

You need to supply a private S3 bucket, which will be used to temporarily house the A-New-Startup source code (so it can be copied into the CodeCommit repo.)

This set of templates uses some static/fixed resource names (stack names, repo name, DynamoDB Table, and much more) for simplicity's sake. 
This means you can only install it ONCE per region (stack will fail with naming conflicts otherwiwse).
If you need multiple installs, use different regions!

This repo is meant for demos to students - so we keep it as simple (as possible).

Additional Requirements:
* Must have AWS CLI v2 installed.  Please note that Cloud9 defaults to V1 - so uninstall and install v2!

# Architecture

This diagram shows the basic outline of how the application will run in the cloud.  Remember, you supply the VPC/Subnets.

![Diagram - A-New-Startup running on EC2/ASG/ALB](/diagrams/aws-a-new-startup-pipeline-demo-compute.png)


A CI/CD Pipeline will be created as well.

![Diagram - Simple CI/CD pipeline to deploy to EC2](/diagrams/aws-a-new-startup-pipeline-demo-cicd.png)

If you run the optional 06-add-test-stage.sh, the Pipeline will be updated as follows:

![Diagram - Simple CI/CD pipeline for a-new-startup with UI Testing](/diagrams/aws-a-new-startup-pipeline-demo-testing.png)

If you run the full pipeline, it will look as follows:

![Diagram - Full CI/CD pipeline including backend resources](/diagrams/aws-a-new-startup-pipeline-demo-cicd-full.png)

# Installation

I recommend setting your AWS_DEFAULT_REGION first:

```
export AWS_DEFAULT_REGION=us-east-1
```

Run the following command, and pass the S3 Bucket Name as the first argument, and a comma delimited list of the 2 PUBLIC subnets:

```
./install.sh "BUCKET_NAME_HERE" "subnet-1234568999,subnet-8298392925"
```

Alternatively, you can run the individual files (This is helpful after the initial install if you are making updates and only want one stack to be updated.)

```
./01-repo.sh "BUCKET_NAME_HERE"

./02-backend.sh

./03-compute.sh "subnet-1234568999,subnet-8298392925"

./04-build-projects.sh

./05-pipeline.sh
```

# What's Next?

The pipeline will kick off automatically after you install it.  Navigate to CodePipeline to see it in action.  

After it is deployed, pull up the ALB DNSName in your browser to see the app. (The DNSName is an output of a-new-startup-compute stack - for convenience)

To run it again, you have the option of using "Release Change" in CodePipeline, or cloning the application source, and making changes.

To update the app (and trigger the CI/CD pipeline again) do the following:

Find the Clone URL (NOTE: Using ssh here) and clone easily with:
```
git clone $(aws codecommit get-repository --repository-name "a-new-startup" --query "repositoryMetadata.cloneUrlSsh" --output text)         
```

Modify some of the visible text in src/views/index.ejs (for an easy and visible change)

```
git commit -a -m "updated version number"

git push
```
The pipeline should then kick off with the latest commit.


# Then what? 

There's an option on the pipeline stack to include a testing stage.

This stage uses a containerized python script with Selenium to perform a UI level test of the code.

Enable this stage by running:
```
./06-add-test-stage.sh
```
Please note that this version of the pipeline will take longer to run, and it will be more complicated.

(Which is why this extra stage isn't included at first)

OR 

Why not make it a real pipeline?  For simplicity's sake we manually deploy the backend resources for the first part of this demo.

But, a real pipeline will need to deploy those resources also.

If you run this command, it will create the full pipeline.

```
./07-pipeline-full.sh
```

# Auto Scaling Group Demo

The ASG has a Dynamic Scaling Policy - Target Tracking of 50% CPU.

The instances have "stress" pre-installed - you can use SSM Command Document to run:
```
stress --cpu 1 --timeout 600s
```

To stress 1 CPU for 10 minutes.  That will trigger the autoscaling rule.   (If you change machine types, use a higher value for --cpu)

# Troubleshooting 

UPDATE: Currently the Amazon Linux 2023 AMI is used instead, because of the deterministic updates this problem should happen less frequently (2023-08-26)

When there are patches outstanding for the Amazon Linux 2 AMI, SSM will force a reboot of the machine very shortly after launching.  This can be confirmed using the "last" command. Unfortunately, this can interrupt the CodeDeploy Agent while it is still running.    This also has the unfortunate side effect that Target Group Health Checks will keep failing, over and over and over, spinning up lots of short-lived machines.

You can try turning OFF the ASG ALB health checks - configure it to use EC2 status only. Does this help?  This probably leaves unhealthy machines but then you can FORCE a deployment through to fix them. (In CodeDeploy find the last failed deployment and simply using "Retry Deployment")

If troubleshooting bootstrapping issues, be sure to disable the automatic scaling policy (50% CPU) - because machines shutting down will cause CodeDeploy failures that look mysterious.

# Uninstall

To uninstall (WARNING - This deletes EVERYTHING created above - no snapshots, no retain - even on the DynamoDB table)

```
./99-uninstall.sh 
```

To uninstall manually:
1. Empty the ArtifactStoreBucket (Look for an output in the a-new-startup-pipeline stack created by pipeline.yaml)
2. Empty the two ECR repos
3. Delete the CloudFormation stacks (There will be four, all named as a-new-startup-* 
3. Delete the a-new-startup.zip and a-new-startup-ui-tests.zip files from your private S3 bucket.

# Other things...

The 01-repo.sh script will pull down the latest A-New-Startup app code and UI Testing code from Github. If that fails, it will use local ZIP archives as a fallback.

97-pull-base-image.sh is called by another shell file to "cache" the Selenium/Headless Chrome image in a private ECR repo. 

If you attempt to pull that particular container image from docker.io - you WILL get throttled at random times - and that's not good for demos!

# A Warning

This code should NOT be considered production ready.  
While some best practices have been incorporated, the primary goal was to keep things SIMPLE so that students can absorb what they are being shown - without tons of extraneous error checking.

# Appendix A - Using custom domain name and HTTPS with Certificate

You can optionally use HTTPS/443 with a custom domain name.

To do this, you MUST already have the Domain as a Hosted Zone in Route 53.

For example, if "example.com" is the Domain in Route 53 with a Hosted Zone Id of "ABC1233FJJB":


```
DOMAIN_NAME="app.example.com"
HOSTED_ZONE_ID="ABC1233FJJB"
./install.sh $BUCKET_NAME $PUBLIC_SUBNET_IDS $DOMAIN_NAME $HOSTED_ZONE_ID
```

You will then be able to access the app via: https://app.example.com - and it will have a valid TLS certificate.


