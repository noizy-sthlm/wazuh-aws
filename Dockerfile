FROM python:3.12-slim-bookworm

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y git curl unzip

RUN pip install --upgrade pip

# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    fi && \
    unzip awscliv2.zip && \
    ./aws/install &&\
    rm -r awscliv2.zip aws

# https://developer.hashicorp.com/terraform/install
RUN curl -s "https://releases.hashicorp.com/terraform/1.13.5/terraform_1.13.5_linux_${TARGETARCH}.zip" -o "terraform.zip" && \
    unzip -q terraform.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip

# https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pip
RUN pip install ansible-core

RUN apt remove -y curl unzip && \
    apt autoremove -y

RUN groupadd wazuh-aws && useradd -m -g wazuh-aws wazuh-aws -s /usr/bin/bash

WORKDIR /home/wazuh-aws

COPY --chown=wazuh-aws  ansible/ ./ansible/
COPY --chown=wazuh-aws  scripts/ ./scripts/
COPY --chown=wazuh-aws  terraform/ ./terraform/
COPY --chown=wazuh-aws  README.md ./
COPY --chown=wazuh-aws  requirements.txt ./
COPY --chown=wazuh-aws  wazuh-aws.py ./

RUN pip install -r ./requirements.txt

USER wazuh-aws

# Wazuh Desktop access
EXPOSE 5601

ENTRYPOINT ["python3", "wazuh-aws.py"]
CMD ["--help"]
