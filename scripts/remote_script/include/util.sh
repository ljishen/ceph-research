#!/usr/bin/env bash

get_supported_distro() {
  local distro
  distro="$(head -n1 /etc/issue | awk '{ print tolower($1) }')"
  if [[ "$distro" != @(ubuntu|debian) ]]; then
    common::err $(( ERR_STATUS_START + 1 )) \
      "Only support Ubuntu and Debian platforms"
  fi
  echo "$distro"
}
