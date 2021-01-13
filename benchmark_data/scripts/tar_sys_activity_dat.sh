#!/usr/bin/env bash
#
# Require bash version >= 4.4

set -euo pipefail


readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# shellcheck source=../../scripts/common.sh
. "$SCRIPT_DIR/../../scripts/common.sh"

if ! common::is_program_installed tar; then
  common::err $(( ERR_STATUS_START + 1 )) \
    "Please install the tar package"
fi

BENCHMARK_DATA_DIR="$SCRIPT_DIR"/../data
# How to loop the results returned by find
#   https://stackoverflow.com/a/9612232
find "$BENCHMARK_DATA_DIR" -type f -path '*/sys_activity/*.dat' -print0 |
  while IFS= read -r -d '' file; do
    TAR_GZ_FILE="$file".tar.gz
    if ! [[ -f "$TAR_GZ_FILE" ]]; then
      common::info "Compressing file '$(readlink --canonicalize "$file")'"
      tar --create --gzip \
        --file="$TAR_GZ_FILE" \
        --directory="$(dirname "$file")" \
        "$(basename "$file")"
    fi
  done

echo
common::info "Done!"
