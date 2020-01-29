#!/usr/bin/env bash

# export PYENV_ROOT="${HOME}/.pyenv"  
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"
# eval "$(pipenv --completion)"
eval "$(rbenv init -)"
export KEYBASE=true
export MFA_STS_DURATION=53200
export NUNA_ROOT="${HOME}/code/analytics"
export SSH_ENV="${HOME}/.ssh/environment"
export ADMIN_USERNAME='alan-admin'
export VAULT_ADDR="https://vault.int.nunahealth.com"
export GOPATH="${HOME}/code/go"
export CDPATH=:..:~:${NUNA_ROOT}/configs/nunahealth/aws/cloudformation:${NUNA_ROOT}/configs/nunahealth:${HOME}/code:

alias nuna="/usr/local/bin/code \${BASH_IT}/custom/nuna.bash"
alias analytics="cd \${NUNA_ROOT}"
alias deployments="cd \${NUNA_ROOT}/configs/nunahealth/aws/cloudformation/deployments"
alias changepw="\${HOME}/code/changepw/changepw.py"
alias bastion="\${HOME}/code/it-bastion-ssh-server/bastion.sh"
alias mfa="vault-auth-aws-init"
alias mfaidm="vault-auth-aws-init -a nuna-identity-management -r admin"

daily() {
    set -x
    vpn \
    && sleep 10 \
    && mfa \
    && sleep 10 \
    && sandbox up \
    && sleep 10 \
    && sandbox ssh
    set +x
}



sandbox() {
    sandbox_help() {
            echo "USAGE:"
            echo "  sandbox <status|up|ssh|stop> [username]"
            echo "  Default username: ${USER}"
    }
    sandbox_name="${2:-${USER}}"
    aws sts get-caller-identity &> /dev/null || { echo "ERROR: Auth first!"; return 1; }
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
            pgrep ssh-agent || ssh-add
            ssh -A -o ConnectTimeout=1 "${sandbox_name}.sandbox.int.nunahealth.com" \
                || echo "ERROR: Can't reach host. Check VPN connection?"
            ;;
        *)
            sandbox_help
            ;;
    esac
}

# shellcheck disable=SC2120
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
            set -x
            aws cloudformation delete-stack --stack-name "${2}"
            { set +x; } 2>&-
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
    if [[ -z "${1}" ]]; then
        printf "ABOUT\n"
        printf "\tDisplays the latest cloud init log for a service + tier.\n"
        printf "USAGE\n"
        printf "\tinitlog <service> <tier> [optional: subrole]\n"
        return 1
    fi
    aws sts get-caller-identity &> /dev/null || { echo "ERROR: Auth first!"; return 1; }
    local latestlog
    if [[ -z "${3:-}" ]]; then
        latestlog=$(aws s3 ls "s3://nunahealth-conf/status/${1}/${2}/" | tail -n1 | awk '{print $4}')
        aws s3 cp "s3://nunahealth-conf/status/${1}/${2}/${latestlog}" - | cat
    else
        latestlog=$(aws s3 ls "s3://nunahealth-conf/status/${1}/$3/${2}/" | tail -n1 | awk '{print $4}')
        aws s3 cp "s3://nunahealth-conf/status/${1}/${3}/${2}/${latestlog}" - | cat
    fi
}

# Called as `prompw prod` this fetches the prod password from vault and puts it in your Mac's clipboard
prompw () {
    aws sts get-caller-identity > /dev/null 2>&1 || { echo "ERROR: 'vault-auth-aws.sh' first!"; return 1; }
    [[ "${1}" == "dev" || "${1}" == "prod" ]] || { echo "ERROR: must specify 'dev' or 'prod'"; return 1; }
    vault read -field=value "nuna/${1}/prometheus/http/password" | pbcopy && echo "clipboarded"
}

rds () {
    local role="${1}"
    local tier="${2}"
    [[ -z ${role} || -z ${tier} ]] && { echo "USAGE: rds <service> <tier>"; return 1; }
    dig "rds-${role}-${tier}.int.nunahealth.com" CNAME +short @10.8.0.2 | sed 's,\..*,,'
}
