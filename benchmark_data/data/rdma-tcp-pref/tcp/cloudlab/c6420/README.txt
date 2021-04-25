These are tests between two c6420 nodes using TCP (default) as the messenger type.


# add the following ceph.conf configuation to vstart.sh
memstore_device_bytes = 107374182400    # 100 GB


# start a memstore Ceph cluster
../src/stop.sh && rm -rf out dev && MON=1 OSD=3 MDS=0 MGR=1 FS=0 RGW=0 ../src/vstart.sh -d -n -x -i 10.10.1.1 --without-dashboard --memstore


# configure the cluster
./ceph-shell -- ceph config set osd osd_max_backfills 32
./ceph-shell -- ceph config set osd osd_recovery_max_active 32
./ceph-shell -- ceph config set osd osd_recovery_max_single_start 8
./ceph-shell -- ceph config set osd osd_recovery_op_priority 63

./ceph-shell -- ceph config show-with-defaults osd.0 | grep "osd_max_backfills\|osd_recovery" | column -t -s ' '

pool_name=bench_failure_management_resource_utilization
num_pgs=128
pool_size=2
./ceph-shell -- ceph osd pool create "$pool_name" "$num_pgs" "$num_pgs" replicated --size "$pool_size" --pg-num-min "$num_pgs"
./ceph-shell -- ceph osd pool set "$pool_name" min_size 1
./ceph-shell -- ceph osd pool set "$pool_name" pg_autoscale_mode off
./ceph-shell -- ceph osd pool application enable "$pool_name" benchmark
./ceph-shell -- ceph osd pool set "$pool_name" noscrub 1
./ceph-shell -- ceph osd pool set "$pool_name" nodeep-scrub 1
./ceph-shell -- ceph osd pool ls detail


# benchmark commands run on the other node
output_file=sys_activity_4KB_write.dat
rm -rf "$output_file"
S_TIME_FORMAT=ISO sar -A -o "$output_file" 2 >/dev/null 2>&1 &
PID=$!
# ./ceph-shell -- rados bench 99999999 write --pool "$pool_name" -b 4096 -O 4096 --max-objects 524288 --concurrent-ios 32 --show-time --write-object --write-omap --write-xattr --no-cleanup >rados_bench_4KB_write.log 2>&1
# ./ceph-shell -- rados bench 99999999 seq --pool "$pool_name" --concurrent-ios 32 --show-time >rados_bench_4KB_seq.log 2>&1
# ./ceph-shell -- rados bench 99999999 write --pool "$pool_name" -b 65536 -O 65536 --max-objects 524288 --concurrent-ios 32 --show-time --write-object --write-omap --write-xattr --no-cleanup >rados_bench_64KB_write.log 2>&1
# ./ceph-shell -- rados bench 99999999 seq --pool "$pool_name" --concurrent-ios 32 --show-time >rados_bench_64KB_seq.log 2>&1
# ./ceph-shell -- rados bench 99999999 write --pool "$pool_name" -b 131072 -O 131072 --max-objects 65536 --concurrent-ios 32 --show-time --write-object --write-omap --write-xattr --no-cleanup >rados_bench_128KB_write.log 2>&1
# ./ceph-shell -- rados bench 99999999 seq --pool "$pool_name" --concurrent-ios 32 --show-time >rados_bench_128KB_seq.log 2>&1
# ./ceph-shell -- rados bench 99999999 write --pool "$pool_name" -b 1048576 -O 1048576 --max-objects 16384 --concurrent-ios 32 --show-time --write-object --write-omap --write-xattr --no-cleanup >rados_bench_1MB_write.log 2>&1
# ./ceph-shell -- rados bench 99999999 seq --pool "$pool_name" --concurrent-ios 32 --show-time >rados_bench_1MB_seq.log 2>&1
# ./ceph-shell -- rados bench 99999999 write --pool "$pool_name" -b 8388608 -O 8388608 --max-objects 2048 --concurrent-ios 32 --show-time --write-object --write-omap --write-xattr --no-cleanup >rados_bench_8MB_write.log 2>&1
# ./ceph-shell -- rados bench 99999999 seq --pool "$pool_name" --concurrent-ios 32 --show-time >rados_bench_8MB_seq.log 2>&1
kill -INT "$PID"
