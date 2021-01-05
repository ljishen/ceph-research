#!/usr/bin/env bash

ceph_volume::_call_func() {
  local -r func_name="$1"
  # check if a function is defined
  #   https://stackoverflow.com/a/85932
  if declare -f "$func_name" >/dev/null; then
    $func_name
  else
    common::err $(( ERR_STATUS_START + 100 )) \
      "Function not implemented: $func_name"
  fi
}

CEPH_VOLUME_OPERATION_CREATE="CREATE"
CEPH_VOLUME_OPERATION_QUERY="QUERY"

ceph_volume::main() {
  if [[ "${CEPH_VOLUME_OPERATION:-}" == "$CEPH_VOLUME_OPERATION_CREATE" ]]; then
    ceph_volume::_call_func create_lvs
  elif [[ "${CEPH_VOLUME_OPERATION:-}" == "$CEPH_VOLUME_OPERATION_QUERY" ]]; then
    ceph_volume::_call_func query_lvs
  else
    common::err $(( ERR_STATUS_START + 101 )) \
      "Unsupport CEPH_VOLUME_OPERATION '$CEPH_VOLUME_OPERATION'"
  fi
}
