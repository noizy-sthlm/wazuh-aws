# Wazuh on AWS

This project automatically deploys Wazuh on AWS. It provides a distributed single-node Wazuh infrastructure suitable for labbing and testing. The infrastructure has been designed to keep the cost low compared to alternative designs such as multi-node or all-in-one deployments.

## How to use this project

### Prerequisites
Before you begin, make sure that you have:

  - Docker Engine on an AMD64- or ARM64-Linux host
  - AWS IAM user (see [IAM user]())
  - SSH key pair configured in AWS EC2

### 1: Configuration files

In your working directory, create a `config/` directory and create:

#### `config/terraform.tfvars`

```bash
allowed_ssh_cidr  = "0.0.0.0/32"        # IP address from where you may ssh into the nat instance for managment
key_name          = "wazuh"             # Your ssh key name as configured in AWS
region            = "eu-north-1"        # The AWS region you want to deploy in
availability_zone = "eun1-az3"          # The availability zone do deploy in

vpc_cidr            = "10.1.0.0/16"     # Make sure that you are not allready utulizing this block in any other vpc in your region 
public_subnet_cidr  = "10.1.0.0/24"     
private_subnet_cidr = "10.1.1.0/24"
agent_ipv4_cidr     = "0.0.0.0/32" # A list of ip/cidr blocks from where you want to accept wazuh-agents
```

#### `state.config`

```bash
# S3 bucket form terraform backend
bucket  = "amzn-s3-demo-bucket1-a1b2c3d4-5678-90ab-cdef-example11111"
region  = "eu-north-1"
```
>[!IMPORTANT]
>"Bucket names must be unique across all AWS accounts in all of the AWS Regions within a partition" ([S3 naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html))

#### `config/secrets.yml`

```bash
# These example passwords should be changed
indexer_admin_password: "AdminPassword" # 'admin' user
wazuh_api_password: "API!Pswrd@123" # "Must comply with requirements (8+ length, uppercase, lowercase, specials chars)"
dashboard_password: "dashboard" # Password for the default 'kibanaserver' user
```
>[!CAUTION]
>Allways use strong passwords

#### `config/id_rsa`
The easiest option is to create a new key-pair in the AWS console and download the private key [Create a key pair for your Amazon EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html)

In the region you are deploying to, set up your ssh key in AWS EC2 and get your private key in the working directory. You can read [Create a key pair for your Amazon EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html) for help on how to do this. The easiest option is to create a new keypair in the AWS Console and download the private key. The key should be in secrets/id_rsa

**Configure an ssh key-pair**

### 2 : AWS Secrets

In your working directory, create a `aws/` directory and create:

#### `aws/credentials`

```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### 3 : Pull and Run the container image

#### Pull the image
```bash
docker pull noizysthlm/wazuh-aws
```

#### Create the S3 backend
```bash
docker run -rm \
  -v $(pwd)/config:/home/wazuh-aws/config \
  -v $(pwd)/aws:/home/wazuh-aws/.aws/ \
  noizysthlm/wazuh-aws create-s3-backend
```

#### Deploy
```bash
docker run -rm \
  -v $(pwd)/config:/home/wazuh-aws/config \
  -v $(pwd)/aws:/home/wazuh-aws/.aws/ \
  noizysthlm/wazuh-aws deploy
```
>[!NOTE]
>Deployment takes approximately **60 minutes** to complete

#### Access the Dashboard
Create a secure SSH-tunnel to access the Dashboard
```bash
docker run -rm \
  -v $(pwd)/config:/home/wazuh-aws/config \
  -v $(pwd)/aws:/home/wazuh-aws/.aws/ \
  -p 443:443 \
  noizysthlm/wazuh-aws deploy
```
Then open yor browser to https://localhost/
>[!NOTE]
>Your browser may warn about an insecure connection. Proceed.

### 2 : Clean up
When you want to destroy the infrastructure
```bash
docker run -rm \
  -v $(pwd)/config:/home/wazuh-aws/config \
  -v $(pwd)/aws:/home/wazuh-aws/.aws/ \
  -p 443:443 \
  noizysthlm/wazuh-aws destroy
```
and delete the S3 backend if you do not plan to deploy again
```bash
docker run -rm \
  -v $(pwd)/config:/home/wazuh-aws/config \
  -v $(pwd)/aws:/home/wazuh-aws/.aws/ \
  -p 443:443 \
  noizysthlm/wazuh-aws destroy
```

## Contribute

Contributions are highly welcome and help improve the project.

You may contribute by:
  - Opening a pull request
  - Creating an issue (questions, feature requests, repport issues)
  - Providing feedback and thoughts