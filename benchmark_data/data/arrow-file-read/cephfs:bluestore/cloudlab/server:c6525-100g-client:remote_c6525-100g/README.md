This test uses four c6525-100g nodes to set up a CephFS cluster, where three of them each runs an OSD daemon on a spare NVMe device, and the remaining one (node-1.test.ucsc-cmps107-pg0.utah.cloudlab.us/10.10.1.1) runs three daemons: a manager deamon, a monitor daemon, and a metadata daemon. An extra c6525-100g server (node-0) is used to run the Arrow benchmark on the mounted CephFS. All these servers are connected with their 100Gbps NIC and the experiments are done over this network. The system configuration is default and no special configuration was applied. The cluster was set up by following the deployment instruction with [cephadm](https://docs.ceph.com/en/pacific/cephadm/install/), which had been automated with the following script:

```bash
$ CEPHADM_RELEASE=v17.0.0 ./ceph-deploy -m 10.10.1.1 -o node-2.test.ucsc-cmps107-pg0.utah.cloudlab.us/10.10.1.2:/dev/nvme1n1 -o node-3.t
est.ucsc-cmps107-pg0.utah.cloudlab.us/10.10.1.4:/dev/nvme1n1 -o node-4.test.ucsc-cmps107-pg0.utah.cloudlab.us/10.10.1.5:/dev/nvme1n1
$
$ ./ceph-shell -- ceph fs volume create cephfs --placement=node-0
```

Then on the benchmark server (node-0), mount the CephFS with

```bash
$ sudo fusermount -u /mnt/cephfs || true
$ sudo mkdir -p /mnt/cephfs
$ sudo chown $(id -nu):$(id -ng) /mnt/cephfs
$ docker run --rm --pid=host --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor:unconfined -v $(pwd)/deployment_data_root/etc:/etc -v /mnt/cephfs:/mnt/cephfs:shared ceph/ceph:v16 ceph-fuse -f /mnt/cephfs
```

Finally, check the mount status on the monitor node (node-1) with

```bash
./ceph-shell -- ceph tell mds.a client ls
```
