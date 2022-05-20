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
alias ws="ssh -A alan.ws.nuna.cloud"
alias cfrun="docker run cfrun"
alias ecr-login="aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 254566265011.dkr.ecr.us-west-2.amazonaws.com"
# alias na="nuna_access"
alias ap="awsprofiles"
alias tokens="jq -r .tokens ~/.config/nuna/vault_store.json | sed -E 's/\"//g'"
alias stable="sshuttle_wrapper stable"
alias testing="sshuttle_wrapper testing"

# NUNA AWS THINGS
a(){
  [[ $1 ]] || { echo "AWS_PROFILE=${AWS_PROFILE}"; return 1; }
  [[ $1 == "unset" ]] && { unset AWS_PROFILE; return; }
  export AWS_PROFILE=$1
}

na() {
  case ${1} in
    env)
      export AWS_DEFAULT_REGION="us-west-2"
      export AWS_ACCESS_KEY_ID=$(nuna_access aws sts --profile "${2:-lob-product-stable}" --role poweruser | jq -r .AccessKeyId)
      export AWS_SECRET_ACCESS_KEY=$(nuna_access aws sts --profile "${2:-lob-product-stable}" --role poweruser | jq -r .SecretAccessKey)
      export AWS_SESSION_TOKEN=$(nuna_access aws sts --profile "${2:-lob-product-stable}" --role poweruser | jq -r .SessionToken)
      echo "exported: AWS_DEFAULT_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN"
      ;;
    unset)
      unset AWS_ACCESS_KEY_ID
      unset AWS_SECRET_ACCESS_KEY
      unset AWS_SESSION_TOKEN
      unset AWS_DEFAULT_REGION
      echo "unsetted"
      ;;
    *)
      nuna_access $@
      ;;
  esac
}

daily() {
  nuna_access login -r admin --all-enclaves
  echo "Syncing nuna_access credentials to ${USER}.ws.nuna.cloud"
  scp ${HOME}/.config/nuna/*.json ${USER}.ws.nuna.cloud:/home/${USER}/.config/nuna
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
      aws ec2 terminate-instances --instance-ids "${2}"
      ;;
    packers)
      aws ec2 describe-instances \
        --filters Name=tag:Name,Values=*Packer* Name=instance-state-name,Values=running \
        --query "Reservations[*].Instances[*].{name: Tags[?Key=='Name'] | [0].Value, instance_id: InstanceId, ip_address: PrivateIpAddress, state: State.Name, launched: LaunchTime}" \
        --output table || return
      prompty "Terminate all running Packer instances?" || return
      for i in $(aws ec2 describe-instances \
                  --filters Name=tag:Name,Values=*Packer* Name=instance-state-name,Values=running \
                  --query "Reservations[*].Instances[*].InstanceId" \
                  --output text)
      do 
        aws ec2 terminate-instances --instance-ids "${i}"
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
