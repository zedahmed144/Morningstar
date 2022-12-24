
# TimeOff.Management

Web application for managing employee absences.

## Features

**Multiple views of staff absences**

Calendar view, Team view, or Just plain list.

**Tune application to fit into your company policy**

Add custom absence types: Sickness, Maternity, Working from home, Birthday etc. Define if each uses vacation allowance.

Optionally limit the amount of days employees can take for each Leave type. E.g. no more than 10 Sick days per year.

Setup public holidays as well as company specific days off.

Group employees by departments: bring your organisational structure, set the supervisor for every department.

Customisable working schedule for company and individuals.

**Third Party Calendar Integration**

Broadcast employee whereabouts into external calendar providers: MS Outlook, Google Calendar, and iCal.

Create calendar feeds for individuals, departments or entire company.

**Three Steps Workflow**

Employee requests time off or revokes existing one.

Supervisor gets email notification and decides about upcoming employee absence.

Absence is accounted. Peers are informed via team view or calendar feeds.

**Access control**

There are following types of users: employees, supervisors, and administrators.

Optional LDAP authentication: configure application to use your LDAP server for user authentication.

**Ability to extract leave data into CSV**

Ability to back up entire company leave data into CSV file. So it could be used in any spreadsheet applications.

**Works on mobile phones**

The most used customer paths are mobile friendly:

* employee is able to request new leave from mobile device

* supervisor is able to record decision from the mobile as well.

**Lots of other little things that would make life easier**

Manually adjust employee allowances
e.g. employee has extra day in lieu.

Upon creation employee receives pro-rated vacation allowance, depending on start date.

Optionally allow employees to see the time off information of entire company regardless of department structure.

## Screenshots

![TimeOff.Management Screenshot](public/img/timeoff-mgmt-screenshot.png?raw=true)

## Installation

### Cloud hosting

Visit https://timeoffmgmt.devopslearninglab.com/

Create company account and use cloud based version.

### Self hosting

Install TimeOff.Management application within your infrastructure:

(make sure you have Node.js (13.14.0) and SQLite3@4.2.0 installed)

```bash
git clone https://gitlab.com/sandeeppillai03/timeoff-management-app-interview.git timeoff-management
cd timeoff-management
npm install
npm start
```
If you are getting a connection timeout error in local at npm install, try the below steps.
* npm config get proxy
* npm config get https-proxy

If you are getting any result from the above commands, then execute the below commands.
* npm config set proxy null
* npm config set https_proxy null

Rerun from npm install step.

Open http://localhost:3000/ in your browser.

## How to?

There are some customizations available.

## How to amend or extend colours available for colour picker?
Follow instructions on [this page](docs/extend_colors_for_leave_type.md).

## Customization

There are few options to configure an installation.

### Make sorting sensitive to particular locale

Given the software could be installed for company with employees with non-English names there might be a need to
respect the alphabet while sorting customer entered content.

For that purpose the application config file has `locale_code_for_sorting` entry.
By default the value is `en` (English). One can override it with other locales such as `cs`, `fr`, `de` etc.

### Force employees to pick type each time new leave is booked

Some organizations require employees to explicitly pick the type of leave when booking time off. So employee makes a choice rather than relying on default settings.
That reduce number of "mistaken" leaves, which are cancelled after.

In order to force employee to explicitly pick the leave type of the booked time off, change `is_force_to_explicitly_select_type_when_requesting_new_leave`
flag to be `true` in the `config/app.json` file.

## Use Redis as a sessions storage

Follow instructions on [this page](docs/SessionStoreInRedis.md).

## Architecture

![Architecture Screenshot](public/img/Architecture_diagram.jpg?raw=true)

### Overview
* The application is built and deployed in AWS cloud in a fully automated manner triggered by a change in the git repo. 
* The application is built into docker containers and pushed to AWS Elastic Container Registry (ECR) through automated CI/CD pipelines.
* The automated CI/CD pipelines are created in Gitlab.
* Terraform is used as IaC tool for provisioning the AWS infrastructure. There are two workspaces (staging and deployment) created using Terraform for building different environments in AWS.
* Terraform steps are integrated into the CI/CD pipeline, thereby automating the entire infrastructure provisioning process. 
* The docker containers are running as container services inside Elastic Container Service (ECS).
* Application is highly available, and load balanced across two availability zones. The high availability is achieved by running minimum two instances of the tasks within the ECS that can be auto scaled to a maximum of 5. All the application components are deployed in subnets that are spread across two availability zones (A & B).


Below are the tools used for building, deploying and running the application.

* **NodeJS** - Framework on which the application is built
* **Docker** - Application is built into containers using Docker.
* **AWS** - Application is deployed on AWS cloud
* **Gitlab**
    * Source code management
    * CI/CD automation tool to build the docker images and push to ECR
    * To run Terraform to create AWS environment resoureces.
* **Terraform** - IaC tool for provisioning the AWS infrastructure. All the terraform code resides in "./deploy" folder. 

### AWS Components used in the project

* **IAM (Identity and Access Management)**
    * All the access management is done using IAM.
    * An IAM user is created with the below policies for limited and controlled access to AWS resources.

    ```
    "ecr:*",
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ec2:*",
    "logs:CreateLogGroup",
    "logs:DeleteLogGroup",
    "logs:DescribeLogGroups",
    "logs:ListTagsLogGroup",
    "logs:TagLogGroup",
    "ecs:DeleteCluster",
    "ecs:CreateService",
    "ecs:UpdateService",
    "ecs:DeregisterTaskDefinition",
    "ecs:DescribeClusters",
    "ecs:RegisterTaskDefinition",
    "ecs:DeleteService",
    "ecs:DescribeTaskDefinition",
    "ecs:DescribeServices",
    "ecs:CreateCluster",
    "iam:CreateServiceLinkedRole",
    "iam:CreateRole",
    "iam:CreatePolicy",
    "rds:AddTagsToResource",
    "rds:ListTagsForResource",
    "iam:GetPolicy",
    "iam:GetRole",
    "iam:TagRole",
    "iam:GetPolicyVersion",
    "iam:ListInstanceProfilesForRole",
    "iam:ListPolicyVersions",
    "iam:DeletePolicy",
    "iam:DeleteRole",
    "iam:AttachRolePolicy",
    "iam:PassRole",
    "iam:ListAttachedRolePolicies",
    "iam:DetachRolePolicy",
    "iam:GetInstanceProfile",
    "iam:AddRoleToInstanceProfile",
    "iam:CreatePolicyVersion",
    "iam:DeletePolicyVersion",
    "iam:CreateInstanceProfile",
    "iam:DeleteInstanceProfile",
    "iam:RemoveRoleFromInstanceProfile",
    "elasticloadbalancing:*",
    "acm:DeleteCertificate",
    "acm:DescribeCertificate",
    "acm:ListTagsForCertificate",
    "acm:RequestCertificate",
    "acm:AddTagsToCertificate",
    "route53:*",
    "rds:DeleteDBSubnetGroup",
    "rds:CreateDBInstance",
    "rds:CreateDBSubnetGroup",
    "rds:DeleteDBInstance",
    "rds:DescribeDBSubnetGroups",
    "rds:DescribeDBInstances",
    "rds:ListTagsForResource",
    "rds:ModifyDBInstance",
    "iam:CreateServiceLinkedRole",
    "rds:AddTagsToResource",
    "application-autoscaling:*",
    "ecs:DescribeServices",
    "ecs:UpdateService",
    "cloudwatch:DescribeAlarms",
    "cloudwatch:PutMetricAlarm",
    "cloudwatch:DeleteAlarms",
    "cloudwatch:DescribeAlarmHistory",
    "cloudwatch:DescribeAlarmsForMetric",
    "cloudwatch:GetMetricStatistics",
    "cloudwatch:ListMetrics",
    "cloudwatch:DisableAlarmActions",
    "cloudwatch:EnableAlarmActions",
    "iam:CreateServiceLinkedRole",
    "sns:CreateTopic",
    "sns:Subscribe",
    "sns:Get*",
    "sns:List*",
    "iam:UpdateAssumeRolePolicy"  
    ```

* **ECR (Elastic Container Registry)**
    * Private repo that stores the application docker containers. 
    * The pushed containers are versioned and tagged using the first 8 characrters of the git commit SHA.

* **ECS cluster (Elastic Container Service)**
    * Runs our application docker containers. Inside the ECS, it runs in FARGATE which is the serverless compute engine for AWS. 
    * This will be pulled from the ECR repository through the NAT gateway.
    * The application is deployed in ECS containers spanning across two availibility zones.
    * It is HA due to auto scaling of tasks within the ECS. There is a minimum of two application instances running across two availibility zones.
    * The auto scaling policy implemented is target tracking scaling policy.  
    * The database credentials like username, password and db name are passed and accessed through environment variables inside the container. This avoids storing the credentials in plain text thereby improving the security of the application. 
    * Terraform file deploy/ecs.tf and deploy/templates/ecs/* contains all the configurations for creating and setting up the ECS.

* **Network**
    * Terraform file deploy/network.tf, deploy/load_balancer.tf and deploy/dns.tf contains all the configurations for creating the network. 
    * The public and private networks are deployed across two availibilty zones (A&B) for HA. 
    * All the requests are handled by a public facing load balancer that routes the traffic to the application running in ECS deployed across  two availibilty zones. 
    * The ECS is configured to accept connections only from the load balancer. 
    * Load balancers serves all the HTTPS request using Certificate Manager for SSL encryption. ALl the HTTP requests are automatically redirected to HTTPS. 

    Below are the network components used for this application. 
    * **VPC (Virtual Private cloud)**
        * Isolates the dev, staging and production environment from each other. 

    * **Public Subnet**
        * For granting public internet access.

    * **Private Subnet**
        * The resources within this subnet will not have public access. Only for private access within the VPC.

    * **Internet Gateway**
        * Set up within the public subnet
        * Allows inbound.outbound internet access.

    * **NAT Gateway**
        * Set up within the public subnet
        * Provides only outbound internet access to the private subnet using a route table

    * **ALB (Application Load Balancer)**
        * Handles request from the user through internet gateway and forwards them to application running in ECS.
        * It is responsible for handling https to keep the requests secure. 
        * It accepts both http and https connections and automatically redirects http to https.
        * Enabled sticky session policy. 

    * **Route 53**
        * For DNS lookup. Custom domain name is added for the application. 
        * Sub domains for environment specific names are defined in deploy/variables.tf file. 

    * **Certificate Manager**
        * Creates/manages certificates for HTTPS
        * Enables secure HTTP connections to ALB. 

* **RDS (Relational database service)**
    * Host the mysql database for the application.
    * Set up in private subnet to restrict public access.
    * Terraform file deploy/database.tf contains all the configurations for creating and setting up the database.
    * DB is highly available as it is deployed across to AZ in the private subnet.
    * Set up in a security group such that it only accepts inbound connection from ECS service and bastion host. It does not allow outbound connections. 

* **EC2 Bastion Server**
    * This is a virtual server that is used only for administrative pusposes.
    * It acts as asingle point of entry to reduce access. 
    * Used to connect to the database from local environment. 
    * It allows direct connection to the private network.
    * Terraform file deploy/bastion.tf and deploy/templates/bastion/* contains all the configurations for creating and setting up the bastion host.

* **S3 bucket**
    * To keep track of infrastructure state using Terraform state files.

* **Amazon Cloudwatch**
    * Created a log group to stores all thge logs from the containers at a centralized location.
    * Simplifies the debugging and troubleshooting process. 
    * ECS uses the cloudwatch metrics for auto scaling the instances. 

## CI/CD flow

![TimeOff.Management Screenshot](public/img/cicd_flow.png?raw=true)

* A merge into the main branch will trigger the docker build and push to AWS ECR repo
* On successful completion of build and push, the staging deployment will trigger.
* For production release, merge (promote) the main branch into production (release) branch.
* This will trigger the staging deployment followed by production deployment. 
* The CI/CD pipeline also has a manual stage to destroy the environments in AWS. This simplifies the process of recreating the environment if required.

## Infrastructure Setup

### Local Infrastructure setup

**Prerequiste softwares**
* **VSCode** - Refer to https://code.visualstudio.com/
* **VSCode Docker Extension** - Refer to https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker
* **VSCode Terraform Extension** - Refer to https://marketplace.visualstudio.com/items?itemName=4ops.terraform
* **Docker Desktop** - Refer to https://www.docker.com/products/docker-desktop/
* **Homebrew** - Refer to https://brew.sh/
* **aws-valut** - Refer to https://github.com/99designs/aws-vault
* **Git** - Refer to https://git-scm.com/

**Setup GitLab account with SSH authentication**
The steps to follow to configure GitLab SSH keys for secure Git connections are as follows:

* Create an account in www.gitlab.com.
* Create an SSH key pair on your personal computer
* Copy the value of the public SSH key
* Log into GitLab and navigate to your account’s Preferences tab
* Create a new GitLab SSH key
* Paste the public key in as the value and set an expiration date
* Copy the SSH URL of the GitLab repo you wish to clone
* Issue a git clone command with the SSH URL

### AWS Setup

* Sign up for AWS (Root) account if you are new user. If not, use your existing AWS account. 
    * Create an AWS free tier account by navigating to https://aws.amazon.com/free/. This step will create the root account fot yourself.
    * This account will have ultimate access over your AWS account.
* Create an IAM user for administration purposes (Recommeneded). This user will be used in all the Terraform tasks for infrastructure provisioning.
    * It is recommended to use IAM user account for all day to day task management.
    * Create a group in IAM by navigating to AWS Console -> Identity and Access Management (IAM) -> User Groups -> Create Groups.
    * Create a group with name "Admin"
    * Attach "AdministratorAccess" policy to this group. 
    * Navigate to AWS Console -> Identity and Access Management (IAM) -> Users -> Add User.
    * Set a user name and pasword.
    * Grant both access types to this user. 
    * Add user to the Admin group. 
* Add a MFA policy to account for security (Best Practice)
        * Create a policy in AWS by navigating to AWS Console -> Identity and Access Management (IAM) -> Policies -> Create Policy.
        * Add the JSON from AWS official docs for MFA policy https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage.html
* Set up AWS Vault
    * Navigate to AWS Console -> Identity and Access Management (IAM) -> User Groups -> Select the IAM user -> Security Credentials
    * Create an access key
    * Open terminal on your local
    * Enter command 
    ```
    aws-vault add <username>
    ```
    * It will prompt for access key and secret. If on MAC, you might have recieved a prompt for keychain password. This encrypts the account details in mac OS keychain and to avoid putting them in clean text file. 
    * This will add credentials to the AWS vault. 
    Run command 
    ```
    "aws-vault exec sandeep.pillai --duration=12h"
    ```
    * You can set the duration based on your requirement. This will authenticate with aws vault and setup a session with aws vault. 
    * This will allow to run AWS commands from local. 

### Set up Terraform

* Navigate to AWS console and login using root id.
* Create a new S3 bucket in AWS. This will be used to store the terraform state file. 
* Go to newly created bucket -> properties -> Enable versioning. 
* This file will persist the current state of AWS infrastructure.
* Create a new folder named "deploy" in the root directory of the source code. This folder will contain all the Terraform files. 
* Create a docker-compose.yml file for running Terraform locally. This file contains the configuration to run docker using Terraform. Recommended to use it with Terraform as it does not lockdown to a specific version.

```
version: '3.7'

services:
  terraform:
    image: hashicorp/terraform:0.12.21
    volumes:
      - .:/infra
    working_dir: /infra
    environment:
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}
```

* version - version of the docker-compose
* image: hashicorp/terraform:0.12.21 - Specifies the docker image for Terraform that is used in the project.
* volumes - create the local directory for the Terraform to work with.
    working_dir - Set the working directory to the created one.
* environment - Passes the secrets stored locally in aws vault to the docker containers to enable it to run it in AWS. 

Below is the list of Terraform commands for running locally.

```
tf-init:
	docker-compose -f deploy/docker-compose.yml run --rm terraform init

tf-fmt:
	docker-compose -f deploy/docker-compose.yml run --rm terraform fmt

tf-validate:
	docker-compose -f deploy/docker-compose.yml run --rm terraform validate

tf-plan:
	docker-compose -f deploy/docker-compose.yml run --rm terraform plan

tf-apply:
	docker-compose -f deploy/docker-compose.yml run --rm terraform apply

tf-destroy:
	docker-compose -f deploy/docker-compose.yml run --rm terraform destroy

tf-workspace-dev:
	docker-compose -f deploy/docker-compose.yml run --rm terraform workspace select dev

tf-workspace-staging:
	docker-compose -f deploy/docker-compose.yml run --rm terraform workspace select staging

tf-workspace-prod:
	docker-compose -f deploy/docker-compose.yml run --rm terraform workspace select prod

```

## Feedback

Please report any issues or feedback by sending an Email to sandeeppillai03@gmail.com

