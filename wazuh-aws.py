import subprocess
import sys
import os
import argparse
import boto3
from botocore.exceptions import ClientError
import json



def check_prerequisites():
    
    required_files = [
        "id_rsa",
        "terraform.tfvars",
        "secrets.yml",
        "state.config"
    ]

    for file in required_files:
        if not os.path.exists(f"config/{file}"):
            print(f"{file} was not found. Create it before proceeding", file=sys.stderr)
            raise FileNotFoundError(f"config/{file} not found")



# Git clone instead of using ansible-galaxy due to upstream bug
# https://github.com/wazuh/wazuh-ansible/issues/1782
def clone_wazuh_ansible():
    if os.path.exists("ansible/wazuh-ansible"):
        print("wazuh-ansible already exists, skipping clone")
        return

    subprocess.run(["git", "clone",
                    "--branch", "v4.14.0",
                    "--depth", "1",
                    "https://github.com/wazuh/wazuh-ansible.git"],
                    cwd="ansible",
                    check=True)



def init_terraform():
    subprocess.run(["terraform", "init",
                    "--input=false",
                    "-backend-config=../config/state.config"],
                   cwd="terraform/",
                   check=True)



def build_infrastructure(auto_approve=True):
    cmd = ["terraform", "apply",
            "-input=false",
            "-var-file=../config/terraform.tfvars"]
    
    if auto_approve:
        cmd.append("-auto-approve")

    subprocess.run(cmd, cwd="terraform/", check=True)
                  
    

def run_ansible_playbooks(verbose=False):

    playbooks = [
        "playbooks/wazuh-indexer.yml",
        "playbooks/wazuh-manager.yml",
        "playbooks/wazuh-dashboard.yml"
    ]

    secrets = "@./../config/secrets.yml"

    for playbook in playbooks:
        cmd = [
            "ansible-playbook",
            "-i", "inventory.ini",
            playbook,
            "--extra-vars", secrets
        ]

        if verbose:
            cmd.append("-v")

        subprocess.run(cmd, cwd="ansible/", check=True)



def destroy_infrastructure(auto_approve=True):
    print("Destroying infrastructure...")

    cmd = [
        "terraform", "destroy",
        "-input=false",
        "-var-file=../config/terraform.tfvars"
    ]

    if auto_approve:
        cmd.append("-auto-approve")

    subprocess.run(cmd, cwd="terraform/", check=True)



def delete_certificates():
    subprocess.run(["rm", "-r", "playbooks/indexer"], cwd="ansible/", check=True)



def create_s3_bucket(name, region):
    # https://docs.aws.amazon.com/AmazonS3/latest/userguide/manage-versioning-examples.html
    # Object are encrypted at rest with S3 managed keys by default
    # The Bucket and containing Objects will be private to the Account and IAM users with permissions by default
    try:
        s3 = boto3.client("s3", region_name=region)
        bucketConfig = {}

        if region != 'us-east-1':
            bucketConfig['CreateBucketConfiguration'] = {'LocationConstraint': region}

        s3.create_bucket(Bucket=name, **bucketConfig)

    
    except ClientError as error:
        if error.response["Error"]["Code"] == "BucketAlreadyOwnedByYou":
            print(f"Backend bucket {name} allready set up")
        else:
            print(f"Could not create backend bucket", file=sys.stderr)
            raise error



def delete_s3_bucket(name, region):
    # https://stackoverflow.com/a/43328646
    try:

        s3 = boto3.resource("s3", region_name=region)
        bucket = s3.Bucket(name)
        bucket.objects.all().delete()
        bucket.delete()
        print("S3 backend deleted: Objects and bucket deleted")
    
    except Exception as e:
        print(f"An error occurred while attempting to delete the bucket: {e}", file=sys.stderr)
        sys.exit(1)



def read_backend_config():
    config = {}

    with open("config/state.config", 'r') as file:
        for line in file:
            line = line.strip()
            if line and (not line.startswith("#")) and ("=" in line):
                key, value = line.split("=", 1)
                config[key.strip()] = value.strip().strip('"')

    return config



def tunnel_dashboard():
    try:
        result = subprocess.run(["terraform", "output", "-json"], cwd="terraform/", capture_output=True, text=True, check=True)

        outputs = json.loads(result.stdout)

        dashboard_ip = outputs["dashboard_ip"]["value"]
        dashboard_instance_id = outputs["dashboard_instance_id"]["value"]
        instance_connect_endpoint_id = outputs["instance_connect_endpoint_id"]["value"]

        subprocess.run(["ssh",
                        "-i", "config/id_rsa",
                        f"ubuntu@{dashboard_instance_id}",
                        "-o", f"ProxyCommand=aws ec2-instance-connect open-tunnel --instance-id {dashboard_instance_id} --instance-connect-endpoint-id {instance_connect_endpoint_id}",
                        "-L", f"443:{dashboard_ip}:443"],
                        check=True)
        
    except Exception as error:
        print(f"Could create the tunnel", file=sys.stderr)
        raise error



def main():

    parser = argparse.ArgumentParser(
        description="Wazuh-AWS Tool",
        epilog="By noizy-sthlm"
        )

    parser.add_argument(
        "action",
        choices=["deploy", "destroy", "create-s3-backend", "delete-s3-backend", "tunnel-dashboard"]
    )

    parser.add_argument(
        "-v", "--verbose",
        action="store_true"
    )

    parser.add_argument(
        "--no-auto-approve",
        action="store_true",
        help="Require interactive approval before Terraform applies any changes"
    )

    args = parser.parse_args()

    try:
        if args.action == "deploy":
            check_prerequisites()
            clone_wazuh_ansible()
            init_terraform()
            build_infrastructure(auto_approve=not args.no_auto_approve)
            run_ansible_playbooks(verbose=args.verbose)

        elif args.action == "destroy":
            check_prerequisites()
            init_terraform()
            destroy_infrastructure(auto_approve=not args.no_auto_approve)
            delete_certificates()

        elif args.action == "create-s3-backend":
            backend_config = read_backend_config()
            create_s3_bucket(backend_config["bucket"], backend_config["region"])

        elif args.action == "delete-s3-backend":
            backend_config = read_backend_config()
            delete_s3_bucket(backend_config["bucket"], backend_config["region"])

        elif args.action == "tunnel-dashboard":
            tunnel_dashboard()
    
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)
        sys.exit(1)


    
if __name__ == "__main__":
    main()