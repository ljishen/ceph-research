.. _deploy-ceph-with-RDMA-support:

===============================
 Deploy Ceph with RDMA support
===============================

Prerequisites
-------------

- RDMA connectivity between all nodes intended for running the Ceph cluster. ::

    Server: rping -s -v server_ip
    Client: rping -c -v –a server_ip

- Docker engine installed on all cluster nodes.

- The ``$USER`` on the monitor node can passwordless ssh to all the other nodes on the same user.

- The same user on each node has passwordless sudo privileges.


Deploy a vanilla Ceph cluster
-----------------------------

You can use whatever tools you like. Here is one way of using the `ceph-deploy`_ script:

.. parsed-literal::

  $ git clone https://github.com/ljishen/ceph-research.git
  $ cd ceph-research/scripts
  $ CEPHADM_RELEASE=\ |CEPHADM_RELEASE| ./ceph-deploy -m MON_IP -o HOST_OSD_DEVICES [-o HOST_OSD_DEVICES]...

where

MON_IP
  The IP address of the Ceph monitor. It must be the address of the host where the current script is running on.

HOST_OSD_DEVICES := host:DEVICE1[,DEVICE2,...]
  ``DEVICE`` is defined by ``DEVICE := /dev/XXX | volume_group/logical_volume``. It must be either a raw block device (not a partition) or a LVM logical volume.

An example of using this script to deploy OSDs on pre-created volume groups and logical volumes on cluster nodes:

.. parsed-literal::

  $ CEPHADM_RELEASE=\ |CEPHADM_RELEASE| ./ceph-deploy -m 10.10.1.2 \\
      -o xl170-1.rdma.ucsc-cmps107-pg0.utah.cloudlab.us:ceph-e0353ee5-9b26-4016-8656-a7d74dfdc086/ceph-lv-7ee534d3-fcc4-47a2-a913-91cb89658948 \\
      -o xl170-2.rdma.ucsc-cmps107-pg0.utah.cloudlab.us:ceph-0ddba72d-ac93-4f3c-86d4-ff25fedcae74/ceph-lv-ff294044-1756-4512-91de-135d1f181fcb \\
      -o xl170-3.rdma.ucsc-cmps107-pg0.utah.cloudlab.us:ceph-891e9205-fbd7-4f0a-b3d1-e7aa03d4672c/ceph-lv-b02b46de-dbd2-477d-b116-49273dfccba4

Make sure the cluster is up and running by checking with script `ceph-shell`_ on the monitor node::

  $ ./ceph-shell -- ceph --status

.. _ceph-deploy: ../scripts/ceph-deploy
.. _ceph-shell: ../scripts/ceph-shell
.. |CEPHADM_RELEASE| replace:: f3a4166379b12d4a7bba667fe761e5b660552db1


Add RDMA configuration
----------------------

- Stop the daemons on each cluster node::

    $ sudo systemctl stop ceph.target

  You can also use the `parallel-ssh`_ script to stop all daemons at once::

    $ ./parallel-ssh --hosts ~/hosts sudo systemctl stop ceph.target

  where the ``~/hosts`` file containers the list of hostnames/IPs of all Ceph nodes.

- Add the following options to the ``[global]`` section of the Ceph ``config`` for each daemon,
  including mon, mgr, and osd, and for file ``deployment_data_root/etc/ceph/ceph.conf``::

    # ceph/src/common/options/global.yaml.in:
    #   ms_type  -- for both the public and the internal network
    #   ms_public_type  -- for the public network
    #   ms_cluster_type  -- for the internal cluster network
    ms_public_type = async+rdma

    ms_async_rdma_device_name = <ib_dev>
    ms_async_rdma_port_num = <ib_port>
    ms_async_rdma_local_gid = <gid_index>

  The above IB values can be found by running the ``show_gids`` command on the deamon node.
  The location of the daemon ``config`` file is ``/var/lib/ceph/<fsid>/<daemon_name>/config``, e.g.,

    /var/lib/ceph/a95675b8-9dc4-11eb-a50c-719848d6105e/mon.xl170-0.rdma.ucsc-cmps107-pg0.utah.cloudlab.us/config

- Add ``--privileged`` to the docker run command of the mgr daemon in file ``/var/lib/ceph/<fsid>/<mgr_daemon_name>/unit.run``

- Enable unlimited memlock (locked-in-memory size) for docker containers by adding the following to ``/etc/docker/daemon.json`` [#]_ on each node::

    {
      "default-ulimits": {
        "memlock": {
          "Hard": -1,
          "Name": "memlock",
          "Soft": -1
        }
      }
    }

  Then restart the docker service with::

    $ sudo systemctl restart docker

.. _daemon configuration file: https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file

- Start the cluster by running the following on each cluster node::

    $ sudo systemctl start ceph.target

  or, with `parallel-ssh`_ you can do::

    $ ./parallel-ssh --hosts ~/hosts sudo systemctl start ceph.target

  Now we can check whether the cluster is back online. On the monitor node, run::

    $ ./ceph-shell -- ceph --status

.. _parallel-ssh: ../scripts/parallel-ssh


Verify RDMA communication
-------------------------

On the monitor node, run ::

  $ ./ceph-shell -- ceph --admin-daemon /var/run/ceph/ceph-<mon_daemon_name>.asok config show | grep ms_public_type
      "ms_public_type": "async+rdma"

  $ ./ceph-shell -- ceph daemon <mon_daemon_name> perf dump AsyncMessenger::RDMAWorker-1
  {
    "AsyncMessenger::RDMAWorker-1": {
        "tx_no_mem": 0,
        "tx_parital_mem": 0,
        "tx_failed_post": 0,
        "tx_chunks": 1239,
        "tx_bytes": 1185281,
        "rx_chunks": 1248,
        "rx_bytes": 139032,
        "pending_sent_conns": 0
    }


Access the cluster with RDMA from client servers
---------------------------------------------

- Install the docker engine on the ARM server.

- Git clone the repository::

    $ git clone https://github.com/ljishen/ceph-research.git

- Copy the ``deployment_data_root`` folder from the monitor node into ``ceph-research/scripts/`` of the client server.

- Update the ``deployment_data_root/etc/ceph/ceph.conf`` by adding the local RDMA information in the same way as in the second step of `Add RDMA configuration`_.

- Check the status of the cluster from client::

    $ cd ceph-research/scripts
    $ export CEPHADM_IMAGE=ceph/ceph:v15
    $ ./ceph-shell -- ceph --status


Miscellaneous
-------------

- If for some reasons the daemons fail to start for more than 5 times in 30min, ``systemctl start ceph.target`` will not start the daemons within the duration, unless ::

    $ sudo systemctl daemon-reload
    $ sudo systemctl stop ceph.target
    $ sudo systemctl start ceph.target

- A bash script to monitor the throughput of a local RDMA device ::

    $ ./rdma_throughput
    Usage: ./rdma-throughput IB_DEVICE [IB_PORT]

    The default IB_PORT is 1 if not specified.

- To tear down the cluster, on the monitor node, run::

    $ ./parallel-cephadm --hosts ~/hosts rm-cluster --force \
        --fsid $(grep -oP 'fsid = \K.+' deployment_data_root/etc/ceph/ceph.conf)


Known issues
------------

- Pacific version (v16.2.0): unable to start the monitor after adding the RDMA configuation

- Octopus version (v15.2.10): cluster can start, but exception when checking the status with ``ceph -s``


References
----------

- How to enable Ceph with RDMA: https://www.hwchiu.com/ceph-with-rdma.html

- Bring Up Ceph RDMA - Developer's Guide: https://community.mellanox.com/s/article/bring-up-ceph-rdma---developer-s-guide


.. [#] A full example of the docker `daemon configuration file`_
