#!/usr/bin/env bash

call_func() {
  local -r func_name="$1"
  # check if a function is defined
  if declare -f "$func_name" >/dev/null; then
    $func_name
  else
    common::err $(( ERR_STATUS_START + 100 )) \
      "Function not implemented: $func_name"
  fi
}

if [[ "${CEPH_VOLUME_OPERATION:-}" == "CREATE" ]]; then
  call_func create_lvs
elif [[ "${CEPH_VOLUME_OPERATION:-}" == "QUERY" ]]; then
  call_func query_lvs
else
  common::err $(( ERR_STATUS_START + 101 )) \
    "Unsupport CEPH_VOLUME_OPERATION '$CEPH_VOLUME_OPERATION'"
fi
