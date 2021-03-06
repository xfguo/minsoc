#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o posix    # Make command substitution subshells inherit the errexit option.
                # Otherwise, the 'command' in this example will not fail for non-zero exit codes:  echo "$(command)"

# A word count should always deliver the number of bytes in the hex file,
# regardless of the number of hex bytes per line.
FIRMWARE_SIZE_IN_BYTES="$(wc -w <"$1")"

vsim -lib minsoc minsoc_bench -pli ../../bench/verilog/vpi/jp-io-vpi.so +file_name=$1 +firmware_size="$FIRMWARE_SIZE_IN_BYTES"
