#!/usr/bin/env zsh
export MFA_STS_DURATION=53200
export SSH_ENV="${HOME}/.ssh/environment"
export ADMIN_USERNAME='${USER}-admin'
export CDPATH=:..:~:${HOME}/code:
export NUNA_MFA_METHOD=token

# Terraform shared cache
# See: https://www.terraform.io/docs/configuration/providers.html#provider-plugin-cache
export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform.d/plugin-cache"

alias ws="ssh -A ${USER}.ws.nuna.cloud"
alias cfrun="docker run cfrun"
alias ecr-login="aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 254566265011.dkr.ecr.us-west-2.amazonaws.com"
alias ap="awsprofiles"
alias tokens="jq -r .tokens ~/.config/nuna/vault_store.json | sed -E 's/\"//g'"
alias stable="sshuttle_wrapper stable"
alias testing="sshuttle_wrapper testing"

# NUNA AWS THINGS
a() {
  [[ $1 ]] || {
    echo "AWS_PROFILE=${AWS_PROFILE}"
    return 1
  }
  [[ $1 == "unset" ]] && {
    unset AWS_PROFILE
    return
  }
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

awsprofiles() {
  rg "\[profile" ${HOME}/.aws/config | cut -d' ' -f2 | sed 's/.$//' | sort
}

idm() {
  [[ -z "${1}" ]] && {
    echo "export AWS_PROFILE=nuna-identity-management-admin"
    return
  }
  AWS_PROFILE=nuna-identity-management-admin "${@}"
}

nuna() {
  which code || "${EDITOR}" "${DOTFILES}/nuna.zsh" && code "${DOTFILES}/nuna.zsh"
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
      --output text); do
      aws ec2 terminate-instances --instance-ids "${i}"
    done
    ;;
  *)
    instancehelp
    ;;
  esac
}
