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

if ! common::is_program_installed sadf; then
  common::err $(( ERR_STATUS_START + 1 )) \
    "Please install the sysstat package"
fi

SADF_VERSION="$(sadf -V | head -n1 | cut --delimiter=' ' --fields=3)"
if ! common::vergte "$SADF_VERSION" "12.1.5"; then
  common::err $(( ERR_STATUS_START + 2 )) \
    "Require the sysstat package version >= 12.1.5"
fi

is_tar_file() {
  local -r file="$1"
  [[ "$file" =~ \.tar\.gz$ ]]
}

: "${BENCHMARK_DATA_DIR:="$SCRIPT_DIR"/../data}"
# How to loop the results returned by find
#   https://stackoverflow.com/a/9612232
find "$BENCHMARK_DATA_DIR" -type f \
  \( -path '*/sys_activity/*.dat' -o -path '*/sys_activity/*.dat.tar.gz' \) \
  -print0 |
  while IFS= read -r -d '' file; do
    SVG_FILE="${file/%.dat*/.svg}"
    if ! [[ -f "$SVG_FILE" ]]; then
      common::info "Generating SVG for file '$(readlink --canonicalize "$file")'"
      DAT_FILE="${file/%.tar.gz}"

      if is_tar_file "$file"; then
        tar --extract --overwrite --gzip --file="$file" \
          --directory="$(dirname "$file")"
      fi

      sadf -g -O autoscale,showidle,showinfo,showtoc -T "$DAT_FILE" -- -A -h \
        >"$SVG_FILE"

      # we can safely delete the datafile because we have the .tar.gz backup
      if is_tar_file "$file"; then
        rm "$DAT_FILE"
      fi
    fi
  done

echo
common::info "Done!"
