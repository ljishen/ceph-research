#!/usr/bin/env bash

set -euo pipefail

readonly FIO_BLOCK_SIZES=("4k" "16k" "64k" "256k" "1m" "4m" "16m")
readonly TASKSET_CPU_LIST=32-63,96-127
readonly FIO_COMMAND="\
   sudo taskset --cpu-list $TASKSET_CPU_LIST \
    fio \
    --iodepth=32 \
    --ioengine=libaio \
    --direct=1 \
    --invalidate=1 \
    --fsync_on_close=1 \
    --randrepeat=1 \
    --norandommap \
    --group_reporting \
    --name nvmeof_hdd \
    --filename=/dev/nvme0n1 \
    --time_based \
    --runtime=30 \
    --output-format=json+"


for num_jobs in $(seq 1 3); do
  cd ../numjobs="$num_jobs"

  for bs in "${FIO_BLOCK_SIZES[@]}"; do
    for idx in $(seq 1 2); do
      $FIO_COMMAND  \
        --rw=randread \
        --bs="$bs" \
        --numjobs="$num_jobs" \
        --output=fio_randread_"$bs".log."$idx"
      sleep 10
    done
  done
  
  for bs in "${FIO_BLOCK_SIZES[@]}"; do
    for idx in $(seq 1 2); do
      $FIO_COMMAND \
        --rw=randwrite \
        --bs="$bs" \
        --numjobs="$num_jobs" \
        --output=fio_randwrite_"$bs".log."$idx"
      sleep 10
    done
  done
done
