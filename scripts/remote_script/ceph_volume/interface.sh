#!/usr/bin/env bash
#
# Require bash version >= 4.4

#include include/util.sh

CEPH_VOLUME_OPERATION_CREATE="CREATE"
CEPH_VOLUME_OPERATION_QUERY="QUERY"

ceph_volume::main() {
  if [[ "${CEPH_VOLUME_OPERATION:-}" == "$CEPH_VOLUME_OPERATION_CREATE" ]]; then
    util::call_func create_lvs
  elif [[ "${CEPH_VOLUME_OPERATION:-}" == "$CEPH_VOLUME_OPERATION_QUERY" ]]; then
    util::call_func query_lvs
  else
    common::err $(( ERR_STATUS_START + 101 )) \
      "Unsupport CEPH_VOLUME_OPERATION '$CEPH_VOLUME_OPERATION'"
  fi
}
