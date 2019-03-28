#!/bin/bash
set -xe
nodepool_status=`systemctl status nodepool-* | grep Active | grep running | wc -l`
zuul_status=`systemctl status zuul-* | grep Active | grep running | wc -l`
mysql_status=`systemctl status mysql* | grep Active | grep running | wc -l`
zk_status=`systemctl status zookeeper* | grep Active | grep running | wc -l`
apache_status=`systemctl status apache* | grep Active | grep running | wc -l`

echo nodepool_status=$nodepool_status, expect 2
echo zuul_status=$zuul_status, expect 5
echo mysql_status=$mysql_status, expect 1
echo zk_status=$mysql_status, expect 1
echo apache_status=$apache_status, expect 1

if [ $nodepool_status -eq 2 ] && [ $zuul_status -eq 5 ] && [ $mysql_status -eq 1 ] && [ $zk_status -eq 1 ] && [ $apache_status -eq 1 ];then
    echo "OK"
        # if node_role is BACKUP, that means this node already change from BACKUP to MASTER
        # if node_role is MASTER, that means this node is healthy.
fi
