#!/usr/bin/env bash
#
# Require bash version >= 4.4

set -euo pipefail


readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# shellcheck source=../../scripts/common.sh
. "$SCRIPT_DIR/../../scripts/common.sh"

if ! common::is_program_installed sadf; then
  common::err $(( ERR_STATUS_START + 1 )) \
    "Please install the sysstat package"
fi

SADF_VERSION="$(sadf -V | head -n1 | cut --delimiter=' ' --fields=3)"
if ! common::vergte "$SADF_VERSION" "12.1.5"; then
  common::err $(( ERR_STATUS_START + 2 )) \
    "Require the sysstat package version >= 12.1.5"
fi

BENCHMARK_DATA_DIR="$SCRIPT_DIR"/..
# How to loop the results returned by find
#   https://stackoverflow.com/a/9612232
find "$BENCHMARK_DATA_DIR" -type f -path '*/sys_activity/*.dat' -print0 |
  while IFS= read -r -d '' file; do
    SVG_FILE="${file/%.dat/.svg}"
    if ! [[ -f "$SVG_FILE" ]]; then
      common::info "Generating SVG for file '$file'"
      sadf -g -O autoscale,showidle,showinfo,showtoc -T file -- -A -h \
        >"$SVG_FILE"
    fi
  done

echo
common::info "Done!"
