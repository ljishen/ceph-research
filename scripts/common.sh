#!/usr/bin/env bash
#
# Require bash version >= 4.4

set -euo pipefail

common::now() { date --iso-8601=ns; }

common::info() {
  local info_prefix=
  if (( ${INFO_LEVEL:-0} )); then
    info_prefix="$(printf '%0.s>' $(seq 1 "$INFO_LEVEL")) "
  fi
  printf "\\033[1;32m[%s][INFO] %s%s\\033[0m\\n" \
    "$(common::now)" "$info_prefix" "$*"
}
common::debug() {
  printf "\\033[1;30m[%s][DEBUG] %s\\033[0m\\n" \
    "$(common::now)" "$*"
}
common::stage() {
  INFO_LEVEL=0
  printf "\\n\\n\\033[1;33m[%s][STAGE] %s\\033[0m\\n" \
    "$(common::now)" "$*"
}
common::err() {
  local -ir exit_status="$1"
  shift
  printf "\\033[1;31m[%s][ERROR] %s\\033[0m\\n" \
    "$(common::now)" "$*" >&2
  exit "$exit_status"
}

# this function should only be used in remote scripts
_REMOTE_OUTPUT_TAG="<REMOTE_OUTPUT> "
common::remote_out() { printf "%s\\n" "$*" | sed "s/^/$_REMOTE_OUTPUT_TAG/"; }

common::parse_remote_out() {
  local line
  while IFS= read -r line; do
    if [[ "$line" =~ ^$_REMOTE_OUTPUT_TAG ]]; then
      echo "${line/#$_REMOTE_OUTPUT_TAG}"
    fi
  done
}

common::vergte() { printf '%s\n%s' "$1" "$2" | sort -rCV; }
if ! common::vergte "${BASH_VERSION%%[^0-9.]*}" "4.4"; then
  common::err 1 "Require bash version >= 4.4"
fi


# https://stackoverflow.com/a/51548669
shopt -s expand_aliases
alias trace_on="{ echo; set -x; } 2>/dev/null"
alias trace_off="{ set +x; } 2>/dev/null"
export PS4='# ${BASH_SOURCE:-"$0"}:${LINENO} - ${FUNCNAME[0]:+${FUNCNAME[0]}()} > '

common::is_set_x() {
  [[ "$-" == *x* ]]
}

common::is_program_installed() {
  local -r prog="$1"
  command -v "$prog" >/dev/null 2>&1
}

common::print_array() {
  local -nr _arr=$1
  local joined
  # "@Q" quote each parameter: https://lwn.net/Articles/701009/
  printf -v joined '%s, ' "${_arr[@]@Q}"
  echo "[${joined%, }]"
}

readonly ERR_CMDLINE_PARAM_UNKNOW=2
readonly ERR_CMDLINE_PARAM_MISSING=3
common::parse_cmdline_params() {
  local -n _param_arr=$1
  shift

  # loop positional params: https://unix.stackexchange.com/a/314041
  local -i return_status=0
  for (( idx = 1; idx <= $#; idx++ )); do
    if [[ "${!idx}" == @(--hosts|--host) ]]; then
      _param_arr+=("${!idx}")
      (( idx++ ))
      if [[ -z "${!idx:-}" ]]; then
        common::err $ERR_CMDLINE_PARAM_MISSING \
          "Missing parameter for '${_param_arr[-1]}'"
      fi
      _param_arr+=("${!idx}")
      continue
    fi

    if [[ "${!idx}" =~ ^(--hosts=|--host=) ]]; then
      _param_arr+=("${!idx}")
      continue
    fi

    # check if a function is defined
    #   https://stackoverflow.com/a/85932
    if ! declare -f handle_add_cmdline_param >/dev/null; then
      common::err $ERR_CMDLINE_PARAM_UNKNOW "Unsupport parameter '${!idx}'"
    fi

    handle_add_cmdline_param "${!idx}" || return_status=$?
    if (( return_status )); then
      common::err $ERR_CMDLINE_PARAM_UNKNOW "Unsupport parameter '${!idx}'"
    fi
  done
}


export SSH_COMM_OPTIONS=(
  -o "GlobalKnownHostsFile=/dev/null"
  -o "LogLevel=ERROR"
  -o "PasswordAuthentication=no"
  -o "StrictHostKeyChecking=no"
  -o "UserKnownHostsFile=/dev/null"
)
export ERR_STATUS_START=4
