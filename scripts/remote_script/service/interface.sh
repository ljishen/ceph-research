#!/usr/bin/env bash
#
# Require bash version >= 4.4

#include include/util.sh

SERVICE_OPERATION_RESTART="RESTART"
SERVICE_OPERATION_STOP="STOP"
SERVICE_OPERATION_QUERY="QUERY"

service::main() {
  if [[ "${SERVICE_OPERATION:-}" == "$SERVICE_OPERATION_RESTART" ]]; then
    util::call_func restart_service
  elif [[ "${SERVICE_OPERATION:-}" == "$SERVICE_OPERATION_STOP" ]]; then
    util::call_func stop_service
  elif [[ "${SERVICE_OPERATION:-}" == "$SERVICE_OPERATION_QUERY" ]]; then
    util::call_func query_service
  else
    common::err $(( ERR_STATUS_START + 101 )) \
      "Unsupport SERVICE_OPERATION '$SERVICE_OPERATION'"
  fi
}
