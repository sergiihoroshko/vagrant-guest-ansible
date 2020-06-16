#!/bin/bash

ANSIBLE_PLAYBOOK=$1
ANSIBLE_HOSTS=$2
ANSIBLE_EXTRA_VARS="$3"
ANSIBLE_REQUIREMENTS_FILE=/vagrant/requirements.yml
TEMP_HOSTS="/tmp/ansible_hosts"

if [ ! -f /vagrant/$ANSIBLE_PLAYBOOK ]; then
        echo "ERROR: Cannot find the given Ansible playbook."
        exit 1
fi

if [ ! -f /vagrant/$ANSIBLE_HOSTS ]; then
        echo "ERROR: Cannot find the given Ansible hosts file."
        exit 2
fi

if ! command -v ansible >/dev/null; then
        echo "Installing Ansible dependencies and Git."
        if command -v yum >/dev/null; then
                sudo yum install ansible
        elif command -v dnf >/dev/null; then
                sudo dnf install ansible
        elif command -v apt-get >/dev/null; then
                sudo apt-get update -qq
                sudo apt-get install software-properties-common
                sudo apt-add-repository --yes --update ppa:ansible/ansible
                sudo apt-get install --yes ansible
        else
                echo "neither yum nor apt-get found!"
                exit 1
        fi
fi

if [ ! -z "$ANSIBLE_EXTRA_VARS" -a "$ANSIBLE_EXTRA_VARS" != " " ]; then
        ANSIBLE_EXTRA_VARS=" --extra-vars $ANSIBLE_EXTRA_VARS"
fi

# stream output
export PYTHONUNBUFFERED=1
# show ANSI-colored output
export ANSIBLE_FORCE_COLOR=true

cp /vagrant/${ANSIBLE_HOSTS} ${TEMP_HOSTS} && chmod -x ${TEMP_HOSTS}
echo "Installing Ansible requirements:"
if test -f "$ANSIBLE_REQUIREMENTS_FILE"; then
        sudo ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts
        sudo ssh-keyscan -H github.com >> ~/.ssh/known_hosts
        sudo ssh-keyscan -H gitlab.com >> ~/.ssh/known_hosts
        sudo ansible-galaxy install -r $ANSIBLE_REQUIREMENTS_FILE
fi
echo "Running Ansible as $USER:"
ansible-playbook /vagrant/${ANSIBLE_PLAYBOOK} --inventory-file=${TEMP_HOSTS} --connection=local $ANSIBLE_EXTRA_VARS
rm ${TEMP_HOSTS}
