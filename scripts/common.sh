#!/usr/bin/env bash
#
# Require bash version >= 4.4

set -euo pipefail

common::now() { date --iso-8601=ns; }

common::err() {
  local -ir exit_status="$1"
  shift
  printf '\033[1;31m%s\t[%s] ERROR: %s\033[0m\n' \
    "${PSSH_HOST:-$(hostname)}" "$(common::now)" "$*" >&2
  exit "$exit_status"
}

# Prevent sourcing the script multiple times in the same namespace
_MAGIC_KEY=OBdJ5O2rWrBnRkvdpxD5FsVAmWo4DrJDxDDpnH3ajMWJQem5eR
if [[ "${_MAGIC_METADATA:-}" == "$_MAGIC_KEY" ]]; then
  common:err 1 "Script has already been sourced: ${BASH_SOURCE[0]}"
fi
_MAGIC_METADATA="$_MAGIC_KEY"

common::info() {
  local info_prefix=
  if (( ${INFO_LEVEL:-0} )); then
    info_prefix="$(printf '%0.s>' $(seq 1 "$INFO_LEVEL")) "
  fi
  printf '\n\033[1;32m%s\t[%s] INFO: %s%s\033[0m\n' \
    "${PSSH_HOST:-$(hostname)}" "$(common::now)" "$info_prefix" "$*"
}
common::debug() {
  printf '\033[1;30m%s\t[%s] DEBUG: %s\033[0m\n' \
    "${PSSH_HOST:-$(hostname)}" "$(common::now)" "$*"
}
common::stage() {
  INFO_LEVEL=0
  printf '\n\n\033[1;33m%s\t[%s] STAGE: %s\033[0m\n' \
    "${PSSH_HOST:-$(hostname)}" "$(common::now)" "$*"
}

# this function should only be used in remote scripts
_REMOTE_OUTPUT_TAG="<REMOTE_OUTPUT> "
common::remote_out() {
  printf '%s\n' "$*" | sed "s/^/$_REMOTE_OUTPUT_TAG/"
}
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
  common::err 2 "Require bash version >= 4.4"
fi


# https://stackoverflow.com/a/51548669
shopt -s expand_aliases
# Write xtrace output to stdout instead of stderr
# (requires bash-4.1)
#   https://tiswww.case.edu/php/chet/bash/CHANGES
#   https://stackoverflow.com/a/55010029/2926646
#   https://stackoverflow.com/a/32689974/2926646
exec {BASH_XTRACEFD}>&1
# shellcheck disable=SC2139
alias trace_on="
  exec $BASH_XTRACEFD>&1
  BASH_XTRACEFD=$BASH_XTRACEFD
  set -x
"
# This alias enables xtrace output to the default file descriptor
# (stderr), which is required to use before operations such as
# sshing to remote to run background tasks.
# shellcheck disable=SC2139
alias trace_on_normal="
  exec $BASH_XTRACEFD>&-
  set -x
"
alias trace_resume="
  if [[ -n \${_XTRACE_ENABLED:-} && \${_XTRACE_ENABLED:-1} -eq 0 ]]; then
    trace_on
  fi
"
# Also discard the stderr in case some operations (e.g., LVM(8)) may
# close the BASH_XTRACEFD descriptor and switch the output of xtrace
# back to stderr.
# shellcheck disable=SC2139
alias trace_off="
  {
    _XTRACE_ENABLED=0
    [[ \$- == *x* ]] || _XTRACE_ENABLED=\$?
    set +x
  } $BASH_XTRACEFD>/dev/null 2>/dev/null
"
export PS4='# ${BASH_SOURCE:-"$0"}:${LINENO} - ${FUNCNAME[0]:+${FUNCNAME[0]}()} > '

# Suppress leaked file descriptor warnings in LVM commands.
#   https://man7.org/linux/man-pages/man8/lvm.8.html
export LVM_SUPPRESS_FD_WARNINGS=1


common::create_stdout_dup() { exec {_STDOUT_DUP}>&1; }
common::to_stdout_dup() {
  tee /dev/fd/${_STDOUT_DUP:=1}
  if (( _STDOUT_DUP != 1 )); then
    exec {_STDOUT_DUP}>&-
  fi
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

readonly ERR_CMDLINE_PARAM_UNKNOW=3
readonly ERR_CMDLINE_PARAM_MISSING=4
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


if [[ -z "${DEPLOYMENT_DATA_ROOT:-}" ]]; then
  export DEPLOYMENT_DATA_ROOT="$PWD"/deployment_data_root
fi
export SSH_COMM_OPTIONS=(
  -o "GlobalKnownHostsFile=/dev/null"
  -o "LogLevel=ERROR"
  -o "PasswordAuthentication=no"
  -o "StrictHostKeyChecking=no"
  -o "UserKnownHostsFile=/dev/null"
)
export ERR_STATUS_START=5
