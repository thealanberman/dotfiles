#!/usr/bin/env bash

# export PYENV_ROOT="${HOME}/.pyenv"  
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"
eval "$(pipenv --completion)"
export MFA_STS_DURATION=53200
export NUNA_ROOT="${HOME}/code/analytics"
export CHEF_ROOT="${HOME}/code/chef-repo"
export SSH_ENV="${HOME}/.ssh/environment"
export ADMIN_USERNAME='alan-admin'

alias nuna="/usr/local/bin/code \${BASH_IT}/custom/nuna.bash"
alias repo="cd \${CHEF_ROOT}"
alias deployments="cd ${NUNA_ROOT}/configs/nunahealth/aws/cloudformation/deployments"
alias chefshell="chef-apply -e 'require \"pry\"; binding.pry'"
alias dev="cd ${HOME}/code"
alias changepw="${HOME}/code/changepw/changepw.py"
alias bastion="${HOME}/code/it-bastion-ssh-server/bastion.sh"
alias markdown="rsync -Phavz ${HOME}/Documents/markdown /keybase/private/thealanberman/"

mfa() {
    case "${1}" in
        check)
            aws sts get-caller-identity
            return
            ;;
        nuna)
            # export AWS_PROFILE='default'
            "${HOME}"/vault-auth-aws-beta.py
            return
            ;;
        experimental)
            export AWS_PROFILE='nuna-experimental'
            ;;
        *)
            echo "usage: mfa <check|nuna|experimental>"
            return
            ;;
    esac
    PIPENV_PIPFILE="${HOME}/aws-mfa/Pipfile" pipenv run aws-mfa
}

get-ami-id() {
    [[ -z ${1} ]] && {
        echo "Usage: get-ami-id <ASG stack_name>"
        return
    }
    /usr/local/bin/aws cloudformation describe-stacks --stack-name "${1}" --query "Stacks[0].Parameters[?ParameterKey=='ImageId'].ParameterValue" --output text
}

cg() {
    # Shorthand for chef generate.
    FIRST="${1}"
    shift
    THEREST="${*}"
    chef generate "${FIRST}" -g "${CHEF_ROOT}/customizations/stove/" "${CHEF_ROOT}/cookbooks/${THEREST}"
}

chefnode() {
    # [ -z ${1} && -z ${2} ] && { echo "Please specify a subcommand and search term."; return 1; }
    pushd "${CHEF_ROOT}" >/dev/null

    case ${1} in
        details)
            for line in $(knife node list | grep "${2}"); do
                knife node show "${line}" -a hostname -a hardware -a macaddress
            done
            ;;
        lastrun)
            knife runs show "$(knife runs list "$(knife node list | grep "${2}")" -r 1 | grep run_id | sed -n -e 's/^run_id:     //p')"
            ;;
        last10)
            knife runs list "$(knife node list | grep "${2}")"
            ;;
        *)
            echo "Valid chefnode subcommands:"
            echo "  details <search term>"
            echo "      Show node hardware and OS details"
            echo "  lastrun <search term>"
            echo "      Show last chef run results"
            echo "  last10 <search term>"
            echo "      Show results of last 10 chef runs."
            ;;
    esac

    popd >/dev/null
}


sandbox() {
    sandbox_name="${2:-${USER}}"
    case "${1}" in
        status)
            [[ "$(/usr/local/bin/aws sts get-caller-identity)" ]] || { echo "ERROR: 'aws-mfa' first!"; return 1; }
            sandbox_instance_id="$(/usr/local/bin/aws cloudformation describe-stack-resource --stack-name CommercialSandboxStateless-"${sandbox_name}" --logical-resource-id CommercialSandboxInstance --query 'StackResourceDetail.PhysicalResourceId' --output text)"
            echo -n "Sandbox ${sandbox_name}.sandbox.int.nunahealth.com is: "
            /usr/local/bin/aws ec2 describe-instance-status --instance-ids "${sandbox_instance_id}" --query "InstanceStatuses[0].InstanceState.Name" --output text
            ;;
        stop)
            [[ "$(/usr/local/bin/aws sts get-caller-identity)" ]] || { echo "ERROR: 'aws-mfa' first!"; return 1; }
            echo "Stopping Sandbox ${sandbox_name}.sandbox.int.nunahealth.com..."
            /usr/local/bin/aws ec2 stop-instances --instance-ids "${sandbox_instance_id}"
            /usr/local/bin/aws ec2 wait instance-stopped --instance-ids "${sandbox_instance_id}" && \
            echo "Sandbox is now stopped."
            ;;
        start)
            [[ "$(/usr/local/bin/aws sts get-caller-identity)" ]] || { echo "ERROR: 'aws-mfa' first!"; return 1; }
            /usr/local/bin/aws ec2 start-instances --instance-ids "${sandbox_instance_id}" && \
            echo "Waiting for Sandbox ${sandbox_name}.sandbox.int.nunahealth.com to start..."
            /usr/local/bin/aws ec2 wait instance-running --instance-ids "${sandbox_instance_id}" && \
            echo "Sandbox is now running."
            ;;
        connect)
            ssh -A -o ConnectTimeout=1 "${sandbox_name}.sandbox.int.nunahealth.com" || \
            echo "ERROR: Check VPN connection?"
            ;;
        *)
            echo "USAGE:"
            echo "  sandbox <status|start|connect|stop> [username]"
            echo "  Default username: ${USER}"
            ;;
    esac
}

# sandbox() {
#     sandbox_name="${2:-${USER}}"
#     ifconfig | grep -q 10.222 || { echo "No VPN connection."; return 1; } # VPN?
#     case "${1}" in
#         connect)
#             ping -q -t1 -c1 "${sandbox_name}.sandbox.int.nunahealth.com" || { return 1; }
#             ssh -A -o ConnectTimeout=1 "${sandbox_name}.sandbox.int.nunahealth.com" || \
#             { echo "ERROR: ssh-add?"; return 1; }
#             ;;
#         stop)
#             ping -q -t1 -c1 "${sandbox_name}.sandbox.int.nunahealth.com" || { return 1; }
#             sandbox_instance_id="$(aws cloudformation describe-stack-resource --stack-name "CommercialSandboxStateless-${sandbox_name}" --logical-resource-id CommercialSandboxInstance --query 'StackResourceDetail.PhysicalResourceId' --output text)"
#             echo "Stopping Sandbox ${sandbox_name}.sandbox.int.nunahealth.com..."
#             /usr/local/bin/aws ec2 stop-instances --instance-ids "${sandbox_instance_id}"
#             /usr/local/bin/aws ec2 wait instance-stopped --instance-ids "${sandbox_instance_id}" &&
#                 echo "Sandbox is now stopped."
#             ;;
#         start)
#             sandbox_instance_id="$(aws cloudformation describe-stack-resource --stack-name "CommercialSandboxStateless-${sandbox_name}" --logical-resource-id CommercialSandboxInstance --query 'StackResourceDetail.PhysicalResourceId' --output text)"
#             /usr/local/bin/aws ec2 start-instances --instance-ids "${sandbox_instance_id}" &&
#                 echo "Waiting for Sandbox ${sandbox_name}.sandbox.int.nunahealth.com to start..."
#             /usr/local/bin/aws ec2 wait instance-running --instance-ids "${sandbox_instance_id}" &&
#                 echo "Sandbox is now running."
#             ;;
#         *)
#             echo "USAGE:"
#             echo "  sandbox <start | stop | connect> [username]"
#             echo "  default username: ${USER}"
#             ;;
#     esac || { echo "ERROR: 'mfa nuna' first?"; }
# }

bootstrapper() {
    source "${CHEF_ROOT}/customizations/scripts/bootstrapper.sh"
}

ssh-add() {
    if [ -n "$1" ]; then
        command ssh-add "${*}"
    else
        command ssh-add -e /usr/local/lib/opensc-pkcs11.so >/dev/null 2>&1
        command ssh-add -s /usr/local/lib/opensc-pkcs11.so
    fi
}

ssh-yubikey-pub() {
    ssh-keygen -D /usr/local/lib/opensc-pkcs11.so -e
}

instance() {
    case "${1}" in
        search)
            /usr/local/bin/awless list instances --filter name="${2}"
            ;;
        *)
            echo "USAGE:"
            echo "  instance search <name or partial name>"
            ;;
    esac
}


stack() {
    case "${1}" in
        delete)
            /usr/local/bin/aws cloudformation delete-stack --stack-name "${2}"
            echo "Waiting for confirmation..."
            /usr/local/bin/aws cloudformation wait stack-delete-complete --stack-name "${2}" && echo "${2} Deleted."
            ;;
        search)
            /usr/local/bin/aws cloudformation describe-stacks --query "Stacks[?StackName!='null']|[?contains(StackName,\`$2\`)==\`true\`].StackName" "${@:3}" --output table
            ;;
        *)
            echo "USAGE:"
            echo "  stack search <search term>"
            echo "  stack delete <stack name>"
            ;;
    esac
}
