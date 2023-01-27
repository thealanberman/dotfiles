# tab completions for homebrewed commands
fpath=("/opt/homebrew/share/zsh/site-functions" $fpath)

# get EPOCHSECONDS
zmodload zsh/datetime

function ws_instanceid() {
  AWS_PROFILE="${2:-corp-infra-stable}" aws ec2 describe-instances --filter \
    "Name=tag:asset_dns_name,Values=${1:-${LOGNAME}}.ws.nuna.cloud" |
    jq -Mr '.Reservations[0].Instances[0].InstanceId'
}

function ws_state() {
  local ws_instanceid="$(ws_instanceid "${@}")"
  if [ "${ws_instanceid}" = "null" ] || [ -z "${ws_instanceid}" ]; then
    echo "ws_state: could not determine instance ID." >&2
    return 1
  fi

  AWS_PROFILE="${2:-corp-infra-stable}" aws ec2 describe-instances --instance-ids "$(ws_instanceid)" |
    jq -Mr ".Reservations[0].Instances[0].State.Name"
}

function stop_ws() {
  local ws_instanceid="$(ws_instanceid "${@}")"
  if [ "${ws_instanceid}" = "null" ] || [ -z "${ws_instanceid}" ]; then
    echo "stop_ws: could not determine instance ID." >&2
    return 1
  fi

  echo "Running: AWS_PROFILE='${2:-corp-infra-stable}' aws ec2 stop-instances --instance-ids '${ws_instanceid}'"
  AWS_PROFILE="${2:-corp-infra-stable}" aws ec2 stop-instances --instance-ids "${ws_instanceid}"
}

function start_ws() {
  local ws_instanceid="$(ws_instanceid "${@}")"
  if [ "${ws_instanceid}" = "null" ] || [ -z "${ws_instanceid}" ]; then
    echo "start_ws: could not determine instance ID." >&2
    return 1
  fi

  echo "Running: AWS_PROFILE='${2:-corp-infra-stable}' aws ec2 start-instances --instance-ids '${ws_instanceid}'"
  AWS_PROFILE="${2:-corp-infra-stable}" aws ec2 start-instances --instance-ids "${ws_instanceid}"
}

function start_ws_and_wait() {
  local _state="$(ws_state "${@}")"

  case "${_state}" in
  running | pending) ;;

  stopped)
    start_ws "${@}"
    ;;
  *)
    echo "start_ws_and_wait: Unexpected instance state '${_state}'" >&2
    return 2
    ;;
  esac

  local _success=-1
  local tries=0
  local delay="0.1"
  local thost="${1:-${LOGNAME}}.ws.nuna.cloud"
  local loopstart="${EPOCHSECONDS}"

  while :; do
    echo "Trying ssh to ${thost} ..."
    ((tries++))
    ssh "${thost}" true
    local _rc="${?}"
    case "${_rc}" in
    0)
      echo "Success on try ${tries} after $((EPOCHSECONDS - loopstart)) seconds."
      _success=0
      break
      ;;
    255)
      echo "Exit code: 255 (expected)"
      if ((delay < 300)); then
        echo "Retrying after ${delay} seconds"
        sleep "${delay}"
        delay="$((delay * 2))"
      else
        echo "Giving up."
        _success="${_rc}"
        break
      fi
      ;;
    *)
      echo "Exit code: ${_rc} (unexpected) - giving up."
      _success="${_rc}"
      break
      ;;
    esac
  done

  return "${_success}"
}
