#!/usr/bin/env bash
export MFA_STS_DURATION=53200
export NUNA_ROOT="${HOME}/code/analytics"
export VAULT_ROOT="${HOME}/code/vault"
export SSH_ENV="${HOME}/.ssh/environment"
export ADMIN_USERNAME='alan-admin'
export CDPATH=:..:~:${NUNA_ROOT}/configs/nunahealth/aws/cloudformation:${NUNA_ROOT}/configs/nunahealth:${HOME}/code:
export NUNA_MFA_METHOD=token

# Terraform shared cache
# See: https://www.terraform.io/docs/configuration/providers.html#provider-plugin-cache
export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform.d/plugin-cache"

alias analytics="cd \${NUNA_ROOT}"
alias deployments="cd \${NUNA_ROOT}/configs/nunahealth/aws/cloudformation/deployments"
alias ws="ssh -A alan.ws.int.nunahealth.com"
alias cfrun="docker run cfrun"
alias ecr-login="aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 254566265011.dkr.ecr.us-west-2.amazonaws.com"
# alias na="nuna_access"
alias ap="awsprofiles"
alias tokens="jq -r .tokens ~/.config/nuna/vault_store.json | sed -E 's/\"//g'"

# NUNA AWS THINGS
a(){
  [[ $1 ]] || { echo "AWS_PROFILE=${AWS_PROFILE}"; return 1; }
  [[ $1 == "unset" ]] && { unset AWS_PROFILE; return; }
  export AWS_PROFILE=$1
}

na() {
  case ${1} in
    env)
      export AWS_ACCESS_KEY_ID=$(nuna_access aws sts --profile lob-product-stable --role poweruser | jq -r .AccessKeyId)
      export AWS_SECRET_ACCESS_KEY=$(nuna_access aws sts --profile lob-product-stable --role poweruser | jq -r .SecretAccessKey)
      export AWS_SESSION_TOKEN=$(nuna_access aws sts --profile lob-product-stable --role poweruser | jq -r .SessionToken)
      echo "exported: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN"
      ;;
    unset)
      unset AWS_ACCESS_KEY_ID
      unset AWS_SECRET_ACCESS_KEY
      unset AWS_SESSION_TOKEN
      echo "unsetted"
      ;;
    *)
      nuna_access $@
      ;;
  esac
}

daily() {
  nuna_access login
  prompty "login to all 3 vaults?" || return
  VAULT_ADDR=https://vault.int.nunahealth.com vault login -method=ldap username="${1:-$USER}" passcode="$(read -rp 'Yubikey tap: ' && echo ${REPLY})"
  VAULT_ADDR=https://vault.staging.nuna.health vault login -method=ldap username="${1:-$USER}" passcode="$(read -rp 'Yubikey tap: ' && echo ${REPLY})"
  VAULT_ADDR=https://vault.nuna.health vault login -method=ldap username="${1:-$USER}" passcode="$(read -rp 'Yubikey tap: ' && echo ${REPLY})"
  VAULT_ADDR=https://vault.testing.nuna.cloud vault login -method=ldap -path=ldap/ad username="${1:-$USER}" passcode="$(read -rp 'Yubikey tap: ' && echo ${REPLY})"
}

ec2user() {
  nuprod -e "${1}" -u ubuntu && nuprod -e "${1}" -u ec2-user
  if [[ "${2}" ]] && [[ "${1}" == "testing" ]]; then
    ssh -A -J ubuntu@bastion.staging.nuna.health "ec2-user@${2}"
  elif [[ "${2}" ]] && [[ "${1}" == "stable" ]]; then
    ssh -A -J ubuntu@bastion.nuna.health "ec2-user@${2}"
  else
    echo "USAGE: ec2user <enclave> <IP>"
  fi
}

ubuntu() {
  nuprod -e "${1}" -u ubuntu
  if [[ "${2}" ]] && [[ "${1}" == "testing" ]]; then
    ssh -A -J ubuntu@bastion.staging.nuna.health "ubuntu@${2}"
  elif [[ "${2}" ]] && [[ "${1}" == "stable" ]]; then
    ssh -A -J ubuntu@bastion.nuna.health "ubuntu@${2}"
  else
    echo "USAGE: ubuntu <enclave> <IP>"
  fi
}

awsprofiles () {
  rg "\[profile" ${HOME}/.aws/config | cut -d' ' -f2 | sed 's/.$//' | sort
}

idm () {
  [[ -z "${1}" ]] && { echo "export AWS_PROFILE=nuna-identity-management-admin"; return; }
  AWS_PROFILE=nuna-identity-management-admin "${@}"
}

nuna() {
  which code || "${EDITOR}" "${DOTFILES}/nuna.bash" && code "${DOTFILES}/nuna.bash"
}

sandbox() {
    sandbox_help() {
            echo "USAGE:"
            echo "  sandbox <status|up|ssh|stop> [username]"
            echo "  Default username: ${USER}"
    }
    sandbox_name="${2:-${USER}}"
    aws sts get-caller-identity &> /dev/null || { echo "ERROR: Auth first!"; return 1; }
    sandbox_instance_id="$(aws cloudformation describe-stack-resource --stack-name CommercialSandboxStateless-"${sandbox_name}" --logical-resource-id CommercialSandboxInstance --query 'StackResourceDetail.PhysicalResourceId' --output text)"
    case "${1}" in
        status)
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
            aws ec2 start-instances --instance-ids "${sandbox_instance_id}" && \
            echo "Waiting for Sandbox ${sandbox_name}.sandbox.int.nunahealth.com to start..."
            aws ec2 wait instance-running --instance-ids "${sandbox_instance_id}" && \
            echo "Sandbox is now running."
            ;;
        connect|ssh)
            pgrep -q ssh-agent || ssh-yubi
            ssh -A -o ConnectTimeout=1 "${sandbox_name}.sandbox.int.nunahealth.com" \
                || echo "ERROR: Can't reach host. Check VPN connection?"
            ;;
        *)
            sandbox_help
            ;;
    esac
}

instance() {
  instancehelp() {
    printf "USAGE:\n\t"
    printf "instance search <name or partial name>\n\t"
    printf "instance ami <name>\n\t"
    printf "instance delete <ids>\n\t"
    printf "instance packers (list+prompt to terminate all packer instances)\n"
  }
  case "${1}" in
    search)
      aws ec2 describe-instances \
        --filters Name=tag:Name,Values="*${2}*" \
        --output table \
        --query "Reservations[*].Instances[*].{name: Tags[?Key=='Name'] | [0].Value, instance_id: InstanceId, ip_address: PrivateIpAddress, state: State.Name}"
      ;;
    ami)
      local instance_id
      if [[ "${2}" =~ ^i- ]]; then
        instance_id="${2}"
      else
        instance_id=$(aws ec2 describe-instances --filter Name=tag:Name,Values="${2}" --query "Reservations[].Instances[].InstanceId" --output text)
      fi
      aws ec2 describe-instances --instance-ids "${instance_id}" \
        --query "Reservations[0].Instances[0].ImageId" \
        --output text
      ;;
    delete)
      aws ec2 terminate-instances --instance-ids"${2}"
      ;;
    packers)
      aws ec2 describe-instances \
      --filters Name=tag:Name,Values=*packer* Name=instance-state-name,Values=running \
      --output table || return
      prompty "Terminate all running Packer instances?" || return
      for i in $(awless list instances --filter name=packer,state=running --columns id,name,state --format json | jq -r .[].ID); do 
        awless delete instance -f --no-sync id="${i}"
      done
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
    info | show | status)
      awless show "${2}"
      ;;
    *)
      stackhelp
      ;;
  esac
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

rds () {
  local role="${1}"
  local tier="${2}"
  [[ -z ${role} || -z ${tier} ]] && { echo "USAGE: rds <service> <tier>"; return 1; }
  dig "rds-${role}-${tier}.int.nunahealth.com" CNAME +short @10.8.0.2 | sed 's,\..*,,'
}
