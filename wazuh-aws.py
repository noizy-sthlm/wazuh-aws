import subprocess
import sys
import os
import argparse



def check_prerequisites():
    if not os.path.exists("config/terraform.tfvars"):
        print("Configuration file not found: config/terraform.tfvars\n",
              "Create the configuration file before deploying", file=sys.stderr)
        raise FileNotFoundError("Configuration file not found")
    
    if not os.path.exists("config/id_rsa"):
        print("SSH key file not found: config/id_rsa\n",
              "Create the SSH key file before deploying", file=sys.stderr)
        raise FileNotFoundError("SSH key file not found")
    
    if not os.path.exists("config/secrets.yml"):
        print("Secrets not found: config/secrets.yml\n",
              "Create secrets.yml before deploying", file=sys.stderr)
        raise FileNotFoundError("Secrets file not found")



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
                    "--input=false"],
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



def main():

    parser = argparse.ArgumentParser(
        description="Wazuh-AWS Tool",
        epilog="By noizy-sthml"
        )

    parser.add_argument(
        "action",
        choices=["deploy", "destroy"]
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
            destroy_infrastructure(auto_approve=not args.no_auto_approve)
            delete_certificates()
    
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)
        sys.exit(1)


    
if __name__ == "__main__":
    main()