#!/usr/bin/env bash

# export PYENV_ROOT="${HOME}/.pyenv"  
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"
# eval "$(pipenv --completion)"
if [ -f $(brew --prefix)/opt/mcfly/mcfly.bash ]; then
  . $(brew --prefix)/opt/mcfly/mcfly.bash
fi
export MFA_STS_DURATION=53200
export NUNA_ROOT="${HOME}/code/analytics"
export CHEF_ROOT="${HOME}/code/chef-repo"
export SSH_ENV="${HOME}/.ssh/environment"
export ADMIN_USERNAME='alan-admin'
export VAULT_ADDR="https://vault.int.nunahealth.com"
export GOPATH="${HOME}/code/go"
export CDPATH=:..:~:${NUNA_ROOT}/configs/nunahealth/aws/cloudformation

alias nuna="/usr/local/bin/code \${BASH_IT}/custom/nuna.bash"
alias repo="cd \${CHEF_ROOT}"
alias analytics="cd \${NUNA_ROOT}/configs/nunahealth/aws"
alias deployments="cd \${NUNA_ROOT}/configs/nunahealth/aws/cloudformation/deployments"
alias chefshell="chef-apply -e 'require \"pry\"; binding.pry'"
alias changepw="\${HOME}/code/changepw/changepw.py"
alias bastion="\${HOME}/code/it-bastion-ssh-server/bastion.sh"
alias mfa="/usr/local/bin/vault-auth-aws.sh"
alias auth="mfa"

get-ami-id() {
    [[ -z ${1} ]] && {
        echo "Usage: get-ami-id <ASG stack_name>"
        return
    }
    aws cloudformation describe-stacks --stack-name "${1}" --query "Stacks[0].Parameters[?ParameterKey=='ImageId'].ParameterValue" --output text
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
    sandbox_help() {
            echo "USAGE:"
            echo "  sandbox <status|start|connect|stop> [username]"
            echo "  Default username: ${USER}"
    }
    sandbox_name="${2:-${USER}}"
    aws sts get-caller-identity > /dev/null 2>&1 || { echo "ERROR: 'mfa' first!"; return 1; }
    case "${1}" in
        status)
            sandbox_instance_id="$(aws cloudformation describe-stack-resource --stack-name CommercialSandboxStateless-"${sandbox_name}" --logical-resource-id CommercialSandboxInstance --query 'StackResourceDetail.PhysicalResourceId' --output text)"
            echo -n "Sandbox ${sandbox_name}.sandbox.int.nunahealth.com is: "
            aws ec2 describe-instance-status --instance-ids "${sandbox_instance_id}" --query "InstanceStatuses[0].InstanceState.Name" --output text
            ;;
        stop)
            echo "Stopping Sandbox ${sandbox_name}.sandbox.int.nunahealth.com..."
            aws ec2 stop-instances --instance-ids "${sandbox_instance_id}"
            aws ec2 wait instance-stopped --instance-ids "${sandbox_instance_id}" && \
            echo "Sandbox is now stopped."
            ;;
        start)
            sandbox_instance_id="$(aws cloudformation describe-stack-resource --stack-name CommercialSandboxStateless-"${sandbox_name}" --logical-resource-id CommercialSandboxInstance --query 'StackResourceDetail.PhysicalResourceId' --output text)"
            aws ec2 start-instances --instance-ids "${sandbox_instance_id}" && \
            echo "Waiting for Sandbox ${sandbox_name}.sandbox.int.nunahealth.com to start..."
            aws ec2 wait instance-running --instance-ids "${sandbox_instance_id}" && \
            echo "Sandbox is now running."
            ;;
        connect)
            ssh -A -o ConnectTimeout=1 "${sandbox_name}.sandbox.int.nunahealth.com" || \
            echo "ERROR: Check VPN connection?"
            ;;
        *)
            sandbox_help
            ;;
    esac
}

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
    stackhelp() {
            echo "USAGE:"
            echo "  stack search <search term>"
            echo "  stack delete <stack name>"
    }
    [ -z "${2}" ] && { stackhelp; return 1; }
    case "${1}" in
        delete)
            aws cloudformation delete-stack --stack-name "${2}"
            echo "Waiting for confirmation..."
            aws cloudformation wait stack-delete-complete --stack-name "${2}" && echo "${2} Deleted."
            ;;
        search)
            aws cloudformation describe-stacks \
            --query "Stacks[?StackName!='null']|[?contains(StackName,\`$2\`)==\`true\`].StackName" "${@:3}" \
            --output table
            ;;
        *)
            stackhelp
            ;;
    esac
}

newscript() {
    curl -s http://bash3boilerplate.sh/main.sh > "${1:-main.sh}" && echo "${1:-main.sh} created."
}

initlog() {
    [[ -z "${1}" ]] && { \
        printf "ABOUT\n\tDisplays the latest cloud init log for a service + tier.\nUSAGE\n\tinitlog <service> <tier>\n"
        return 1
        }
    local latestlog
    latestlog=$(aws s3 ls "s3://nunahealth-conf/status/${1}/${2}/" | tail -n1 | awk '{print $4}')
    [[ "${3}" == "cat" ]] && \
    aws s3 cp "s3://nunahealth-conf/status/${1}/${2}/${latestlog}" - | cat || \
    aws s3 cp "s3://nunahealth-conf/status/${1}/${2}/${latestlog}" - | bat
}

# Called as `prompw prod` this fetches the prod password from vault and puts it in your Mac's clipboard
prompw () {
    aws sts get-caller-identity > /dev/null 2>&1 || { echo "ERROR: 'vault-auth-aws.sh' first!"; return 1; }
    [[ "${1}" == "dev" || "${1}" == "prod" ]] || { echo "ERROR: must specify 'dev' or 'prod'"; return 1; }
    vault read -field=value "nuna/${1}/prometheus/http/password" | pbcopy && echo "clipboarded"
}
