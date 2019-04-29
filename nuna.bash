#!/usr/bin/env bash

# export PYENV_ROOT="${HOME}/.pyenv"  
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"
# eval "$(pipenv --completion)"
eval "$(rbenv init -)"
export MFA_STS_DURATION=53200
export NUNA_ROOT="${HOME}/code/analytics"
export CHEF_ROOT="${HOME}/code/chef-repo"
export SSH_ENV="${HOME}/.ssh/environment"
export ADMIN_USERNAME='alan-admin'
export VAULT_ADDR="https://vault.int.nunahealth.com"
export GOPATH="${HOME}/code/go"
export CDPATH=:..:~:${NUNA_ROOT}/configs/nunahealth/aws/cloudformation:${NUNA_ROOT}/configs/nunahealth:~/code:

alias nuna="/usr/local/bin/code \${BASH_IT}/custom/nuna.bash"
alias repo="cd \${CHEF_ROOT}"
alias analytics="cd \${NUNA_ROOT}/configs/nunahealth/aws"
alias deployments="cd \${NUNA_ROOT}/configs/nunahealth/aws/cloudformation/deployments"
alias chefshell="chef-apply -e 'require \"pry\"; binding.pry'"
alias changepw="\${HOME}/code/changepw/changepw.py"
alias bastion="\${HOME}/code/it-bastion-ssh-server/bastion.sh"
alias mfa="vault-auth-aws.sh"
alias auth="vault-auth-aws.sh"

# knife() {
#     pushd "${CHEF_ROOT}" || return
#     /usr/local/bin/knife "${*}"
#     popd || return
# }

chefnode() {
    pushd "${CHEF_ROOT}" || return

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

    popd || return
}


sandbox() {
    sandbox_help() {
            echo "USAGE:"
            echo "  sandbox <status|start|connect|stop> [username]"
            echo "  Default username: ${USER}"
    }
    sandbox_name="${2:-${USER}}"
    aws sts get-caller-identity > /dev/null 2>&1 || { echo "ERROR: 'vault-auth-aws.sh' first!"; return 1; }
    case "${1}" in
        status)
            sandbox_instance_id="$(aws cloudformation describe-stack-resource --stack-name CommercialSandboxStateless-"${sandbox_name}" --logical-resource-id CommercialSandboxInstance --query 'StackResourceDetail.PhysicalResourceId' --output text)"
            echo -n "Sandbox ${sandbox_name}.sandbox.int.nunahealth.com is: "
            aws ec2 describe-instance-status --instance-ids "${sandbox_instance_id}" --query "InstanceStatuses[0].InstanceState.Name" --output text
            ;;
        stop|halt)
            echo "Stopping Sandbox ${sandbox_name}.sandbox.int.nunahealth.com..."
            aws ec2 stop-instances --instance-ids "${sandbox_instance_id}"
            aws ec2 wait instance-stopped --instance-ids "${sandbox_instance_id}" && \
            echo "Sandbox is now stopped."
            ;;
        start|up)
            sandbox_instance_id="$(aws cloudformation describe-stack-resource --stack-name CommercialSandboxStateless-"${sandbox_name}" --logical-resource-id CommercialSandboxInstance --query 'StackResourceDetail.PhysicalResourceId' --output text)"
            aws ec2 start-instances --instance-ids "${sandbox_instance_id}" && \
            echo "Waiting for Sandbox ${sandbox_name}.sandbox.int.nunahealth.com to start..."
            aws ec2 wait instance-running --instance-ids "${sandbox_instance_id}" && \
            echo "Sandbox is now running."
            ;;
        connect|ssh)
            ssh -A -o ConnectTimeout=1 "${sandbox_name}.sandbox.int.nunahealth.com" \
                || echo "ERROR: Can't reach host. Check VPN connection?" \
                && echo "sandbox session ended"
            ;;
        *)
            sandbox_help
            ;;
    esac
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
    instancehelp() {
        printf "USAGE:\n\t"
        printf "instance search <name or partial name>\n\t"
        printf "instance ami <name or partial name>\n\t"
        printf "instance ssh <name or private IP>\n\t"
        printf "instance ssh <service> <tier>\n"
    }
    case "${1}" in
        search)
            awless list instances --filter name="${2}"
            ;;
        ssh)
            [[ "${2}" ]] || { instancehelp; return 1; }
            [[ "${3}" ]] && role="role=${2}-${3}" || role="foo"
            local i
            i=$(awless list instances --filter name="${2}" --tag "${role}" --columns name --no-headers --format csv)
            awless ssh --private "${USER}@${i}"
            ;;
        ami)
            local instance_id
            instance_id=$(awless list instances --filter name="${2}" --ids | grep '^i-')
            aws ec2 describe-instances --instance-ids "${instance_id}" \
                --query "Reservations[0].Instances[0].ImageId" \
                --output text
            ;;
        *)
            instancehelp
            ;;
    esac
}

stack() {
    stackhelp() {
            printf "USAGE:\n\t"
            printf "stack search <search term>\n\t"
            printf "stack info <stack name>\n\t"
            printf "stack ami <stack name>\n\t"
            printf "stack delete <stack name>\n"
    }
    [ -z "${2}" ] && { stackhelp; return 1; }
    case "${1}" in
        delete)
            aws cloudformation delete-stack --stack-name "${2}"
            echo "Waiting for confirmation..."
            aws cloudformation wait stack-delete-complete --stack-name "${2}" && echo "${2} Deleted."
            ;;
        search)
            awless list stacks --filter name="${2}"
            ;;
        ami)
            aws cloudformation describe-stacks --stack-name "${2}" \
                --query "Stacks[0].Parameters[?ParameterKey=='ImageId'].ParameterValue" \
                --output text
            ;;
        info|show|status)
            awless show "${2}"
            ;;
        *)
            stackhelp
            ;;
    esac
}

newscript() {
    cp "${HOME}/main.sh" "${1:-main.sh}" && echo "${1:-main.sh} created."
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
