# Overview

These CloudFormation templates create an EC2/ASG/ALB dev environment for the A-New-Startup application, and a complete CI/CD pipeline.

This set of templates will create resources that cost money - including some with billing per hour (EC2 instances, Application Load Balancer, etc.)

The A-New-Startup application source code will be placed into a CodeCommit repo.
Next, an Application Load Balancer with an Auto Scaling Group and Target Group will be created.
A Launch Template is used in conjunction with an ASG.  
The Launch Template specifies a few minor things, including a User Data to install the CodeDeploy agent.
A Pipeline uses CodePipeline/CodeBuild/CodeDeploy to deploy the A-New-Startup application to the instances in the ASG.

This codebase is meant for the DevOps Engineering on AWS class.  As such, it follows a simple "script" and keeps things simple.

This solution is PVRE Friendly, as the EC2 instances will use Amazon Linux 2023 and will have the SSM agent installed and with proper permissions via Instance Profile/IAM Role.

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

## EC2 Instances Failing Health Checks 
The most common/likely issue you will encounter is the EC2 instances not becoming healthy - and therefore being terminated by the ELB Health Checks.

Consider all of the following:

There is an Application Load Balancer (ALB) with health checks pointed to an Auto Scaling Group (ASG) that contains a Dynamic Scaling Policy (50% CPU, 2 minimum instances.)

This means, while you are troubleshooting machines may be terminated by either the ELB or the ASG.  Therefore if you are experiencing health problems do the following so you can better reason about any behavior you are seeing:

1) Temporarily disable the ELB health checks by editing the ASG in Console. EC2 health checks are required, but ELB are optional. There is a generous 10 minute grace period for health checks specified in the compute.yaml template, but it is still better to disable this.
2) Temporarily disable the Dynamic Scaling policy by editing the ASG in Console.

Consider also that to have the application up and running and listening on Port 3000 (and therefore able to pass a health check):

1. The EC2 User Data must run successfully to ensure prerequisites are in place
2. The CodeDeploy agent must be running on the machine. Machine must be able to talk to CodeDeploy (typically via Internet)
3. A Deployment must have executed successfully.

## Troubleshooting User Data failures

The EC2 User Data (see compute.yaml) must execute successfully on launch.

    * Use Session Manager to check:
        * /var/log/cloud-init.log
        * /var/log/cloud-init-output.log

    Look for any indications that User Data didn't run to completion.   

    You may see IMDSv2 throttling messages that come from the cloud-init process. I don't know how to fix that.

    Look for indications that the machine may have been terminated by something (ELB Healthcheck, ASG scale-in, Rebooting for patches) before it was done. 

    On linux, you can run the "last" command to see reboot history. Sometimes patches require a reboot.

    ### Why don't we ? 

    Why don't we use cfn-init/cfn-signal to fail the stack if a machine doesn't get healthy? THat only helps on initial launch. These User Data problems can also occur during scale out.

    Why don't we just build a custom AMI with all the pre-reqs on it? That's a lot of work to stay on top of patching... probably too much ongoing work for a trainer (But that would eliminate these issues)  

## CodeDeploy agent not running

    Run :
    ```
    systemctl status codedeploy 
    ```
    If it's not in Active status, check the codedeploy logs: https://docs.aws.amazon.com/codedeploy/latest/userguide/deployments-view-logs.html

    Other things:
    
    Is the machine in a Public subnet with a public IP? It has to be able to talk to the CodeDeploy AWS APIs.

## CodeDeploy deployment failing.

Go to the CodeDeploy console -> "Deployments"

Look for errors.

Which stage/hook are the failures occurring in?

Are all the pre-requisites available? (run "node -v")


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

If you attempt to pull that particular container image from DockerHub/docker.io - you WILL get throttled at random times - and that's not good for demos!

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
