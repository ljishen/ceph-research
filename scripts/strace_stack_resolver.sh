#!/usr/bin/env bash
#
# This script uses addr2line to resolve the addresses of function
# calls produced by 'strace --stack-traces', e.g.,
# 
# $ sudo strace -p <pid> -f -i -k -o strace.log -tt -T -y -yy
# $ sudo ./strace_stack_resolver.sh strace.log
#
# ---
#
# Example translation:
#
# [INPUT]
# 78068 15:13:40.011396 [00007fc978e0655e] madvise(0x7fc74e87a000, 3866, MADV_WILLNEED) = 0 <0.000013>
# > /lib/x86_64-linux-gnu/libc-2.27.so() [0x10f55e]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x10f5cce]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x10f66be]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1115a7a]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b1a1ef]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b19a88]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b18707]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b18674]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b05b29]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b05a5e]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1ac0e3f]
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1ac1b3a]
# > /workdir/arrow/python/pyarrow/_feather.cpython-36m-x86_64-linux-gnu.so() [0x9c93]
# > /usr/bin/python3.6() [0x151325] 
#
# [OUTPUT]
# 78068 15:13:40.011396 [00007fc978e0655e] madvise(0x7fc74e87a000, 3866, MADV_WILLNEED) = 0 <0.000013>
# > /lib/x86_64-linux-gnu/libc-2.27.so() [0x10f55e] -> posix_madvise at ??:?
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x10f5cce] -> _ZN5arrow2io16MemoryMappedFile6ReadAtEll at /workdir/arrow/cpp/src/arrow/io/file.cc:666 (discriminator 3)
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x10f66be] -> _ZN5arrow2io16MemoryMappedFile9ReadAsyncERKNS0_9IOContextEll at /workdir/arrow/cpp/src/arrow/io/file.cc:702
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1115a7a] -> _ZN5arrow2io16RandomAccessFile9ReadAsyncEll at /workdir/arrow/cpp/src/arrow/io/interfaces.cc:168
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b1a1ef] -> _ZN5arrow3ipc25RecordBatchFileReaderImpl15ReadFooterAsyncEPNS_8internal8ExecutorE at /workdir/arrow/cpp/src/arrow/ipc/reader.cc:1228
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b19a88] -> _ZN5arrow3ipc25RecordBatchFileReaderImpl10ReadFooterEv at /workdir/arrow/cpp/src/arrow/ipc/reader.cc:1215
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b18707] -> _ZN5arrow3ipc25RecordBatchFileReaderImpl4OpenEPNS_2io16RandomAccessFileElRKNS0_14IpcReadOptionsE at /workdir/arrow/cpp/src/arrow/ipc/reader.cc:1115
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b18674] -> _ZN5arrow3ipc25RecordBatchFileReaderImpl4OpenERKSt10shared_ptrINS_2io16RandomAccessFileEElRKNS0_14IpcReadOptionsE at /workdir/arrow/cpp/src/arrow/ipc/reader.cc:1108
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b05b29] -> _ZN5arrow3ipc21RecordBatchFileReader4OpenERKSt10shared_ptrINS_2io16RandomAccessFileEElRKNS0_14IpcReadOptionsE at /workdir/arrow/cpp/src/arrow/ipc/reader.cc:1330 (discriminator 1)
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1b05a5e] -> _ZN5arrow3ipc21RecordBatchFileReader4OpenERKSt10shared_ptrINS_2io16RandomAccessFileEERKNS0_14IpcReadOptionsE at /workdir/arrow/cpp/src/arrow/ipc/reader.cc:1323 (discriminator 1)
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1ac0e3f] -> _ZN5arrow3ipc7feather12_GLOBAL__N_18ReaderV24OpenERKSt10shared_ptrINS_2io16RandomAccessFileEE at /workdir/arrow/cpp/src/arrow/ipc/feather.cc:710 (discriminator 3)
# > /workdir/dist/lib/libarrow.so.500.0.0() [0x1ac1b3a] -> _ZN5arrow3ipc7feather6Reader4OpenERKSt10shared_ptrINS_2io16RandomAccessFileEE at /workdir/arrow/cpp/src/arrow/ipc/feather.cc:781 (discriminator 1)
# > /workdir/arrow/python/pyarrow/_feather.cpython-36m-x86_64-linux-gnu.so() [0x9c93] -> _ZL45__pyx_tp_new_7pyarrow_8_feather_FeatherReaderP11_typeobjectP7_objectS2_ at _feather.cpp:?
# > /usr/bin/python3.6() [0x151325] -> ?? ??:0 


set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 strace.log

strace.log is an output file from strace with option '--stack-traces' enabled.

EOF
}

if (( $# != 1 )); then
  usage
  exit
fi

STRACE_LOG=$1
if ! [[ -w  "$STRACE_LOG" ]]; then
  printf '%s does not exist or is not writable.'  "$STRACE_LOG" >&2
  exit 1
fi

awk '
  $1 == ">" {
    src = $2
    gsub(/\(.*$/, "", src)
    addr = $NF
    gsub(/\[|\]/, "", addr)
    cmd = "addr2line -C -e " src " -f " addr " -p"
    cmd | getline output
    close(cmd)

    gsub(/$/, " -> " output, $0)
  }

  { print }
' "$STRACE_LOG" > "$STRACE_LOG".resolved
