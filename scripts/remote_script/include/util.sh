#!/usr/bin/env bash
#
# Require bash version >= 4.4

util::call_func() {
  local -r func_name="$1"
  # check if a function is defined
  #   https://stackoverflow.com/a/85932
  if declare -f "$func_name" >/dev/null; then
    $func_name
  else
    common::err $(( ERR_STATUS_START + 1000 )) \
      "Function not implemented: $func_name"
  fi
}

util::get_supported_distro() {
  local distro
  distro="$(head -n1 /etc/issue | awk '{ print tolower($1) }')"
  if [[ "$distro" != @(ubuntu|debian) ]]; then
    common::err $(( ERR_STATUS_START + 1001 )) \
      "Only support Ubuntu and Debian platforms"
  fi
  echo "$distro"
}
