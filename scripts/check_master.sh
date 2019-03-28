#!/bin/bash
set -ex
master_ip=$1

function getRet(){
    if ! ssh -o StrictHostKeyChecking=no -i /root/key root@$master_ip < /root/master_wanted_services.sh | grep OK; then
        echo "ERROR"
    fi
}

pre_exec_status=$(getRet)
if [ $pre_exec_status == 'OK' ];then
    exit 0
else
    exit 1
fi
