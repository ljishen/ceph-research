#!/usr/bin/env bash
#
# Require bash version >= 4.4

set -euo pipefail

common::info() { printf "\\033[1;32m[INFO] %s\\033[0m\\n" "$*"; }
common::debug() { printf "\\033[1;30m[DEBUG] %s\\033[0m\\n" "$*"; }
common::err() {
  local -ir exit_status="$1"
  shift
  printf "\\033[1;31m[ERROR] %s\\033[0m\\n" "$*" >&2
  exit "$exit_status"
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

common::check_if_parallel_ssh_installed() {
  if ! command -v "parallel-ssh" >/dev/null 2>&1; then
    common::err 2 "Please install parallel-ssh"
  fi
}

common::print_array() {
  local -nr _arr=$1
  local joined
  # "@Q" quote each parameter: https://lwn.net/Articles/701009/
  printf -v joined '%s, ' "${_arr[@]@Q}"
  echo "[${joined%, }]"
}


export SSH_COMM_OPTIONS=(
  -o "GlobalKnownHostsFile=/dev/null"
  -o "LogLevel=ERROR"
  -o "PasswordAuthentication=no"
  -o "StrictHostKeyChecking=no"
  -o "UserKnownHostsFile=/dev/null"
)
export PARALLEL_SSH_OPTIONS=(
  --extra-args "${SSH_COMM_OPTIONS[*]}"
  "--par=${PARALLEL_SSH_THREADS:-5}"
  --inline
  --send-input
  --print
)
export ERR_STATUS_START=2
