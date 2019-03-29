#!/bin/bash

# $1 is the role of the script caller
# $2 is the remote node ip
set -ex

monitor_node=$1
process_target=$2
remote_ip=$3
from_kp_role=$4

xiyuan_toy="cli.py"

# notify_down.sh
# 1. check remote ip is alive
function checkRemoteAlive(){
    if ! ping -c 1 $1 -W 3 | grep rtt > /dev/null;then
        echo "ERROR"
    else
        echo "OK"
    fi
}

pre_exec_status=$(checkRemoteAlive ${remote_ip})

# Case: if both side is alive, we can decide which one to do the process
# 1. if local role is MASTER, BACKUP side is alive, let BACKUP side do it.
# 2. if local role is BACKUP, MASTER side is alive, let MASTER side do it.

# Case description:
# Now there are 3 deployment in BLUE lab:
# 10.79.191.191 Default Master <---> 111.20.68.219:1234
# 10.79.157.157 Default BACKUP <---> 111.20.68.219:1235
# 10.79.159.159 New deployment <---> 111.20.68.219:1236

function getNewDeployment(){
    echo "10.79.159.159"
}

function fullyShutDownDeployment(){
    # TODO
    # Clean resources
    return 0
}

if [ ! -f "/root/$xiyuan_toy" ];then
    # Get yuan God's toy
    wget https://raw.githubusercontent.com/wangxiyuan/Toy/master/github-app-webhook-url-update-tool/cli.py
fi

if [ $process_target == 'MASTER' ] && [ $pre_exec_status == "OK" ] && [ $from_kp_role == "BACKUP" ];then
    # 1. if local role(process target) is MASTER, keepalived BACKUP side is alive, let keepalived BACKUP side do it.
    # workflow:
    # MASTER deployment is Down.
    # 1) start local services
    # 2) change the github app webhook
    # 3) process extenal DNS
    # 4) change local as new MASTER deployment
    # 5) cleanup MASTER side resources
    # 6) setup a new BACKUP deployment
    # 7) update local keepalived config
#    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /root/key root@$monitor_node < "systemctl stop keepalived.service"
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /root/key root@10.79.192.192 < "systemctl stop keepalived.service"
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /root/key root@$remote_ip < /root/start_2_services
    $(fullyShutDownDeployment $monitor_node)
    # python3 cli.py --user <user_name> --password <password> --app <app_name> --ip <webhook_ip> --port <webhook_port>
    python3 cli.py --user moo-ai --password mooopenlab1 --app testopenlabha --ip 111.20.68.219 --port 1236
    # After change the webhook, that means we already change local node as a new MASTER node.
    # But the keepalived configuration need to change from BACKUP to MASTER.
    # usage: ge [-h] --kp-role <kp_role> --master-ip <master_ip> --backup-ip
    #      <backup_ip> [--vip <vip>] [--interface <interface>]
    # (TODO) notes, here we have not implement, so the new backup-ip should be 10.79.159.159 for now
    new_backup_ip=$(getNewDeployment)

    # As we set local as new MASTER, we need to make sure that the new backup deployment should shutdown the necessary services
    ssh -o StrictHostKeyChecking=no -i /root/key root@$new_backup_ip < /root/stop_2_services

    python /root/genarate_kp_conf.py --master-ip $remote_ip --backup-ip $new_backup_ip --kp-role MASTER
    # Also change the local keepalived config for new deployment
    # (TODO) using systemctl to restart keepalived.
    systemctl restart keepalived.service
elif [ $process_target == 'BACKUP' ] && [ $pre_exec_status == "OK" ] && [ $from_kp_role == "BACKUP" ];then
    echo "reach BACKUP BACKUP -- SKIP"
    exit 0
elif [ $process_target == 'MASTER' ] && [ $pre_exec_status == "OK" ] && [ $from_kp_role == "MASTER" ];then
    echo "reach MASTER MASTER -- SKIP"
    exit 0
elif [ $process_target == 'BACKUP' ] && [ $pre_exec_status == "OK" ] && [ $from_kp_role == "MASTER" ];then
    # 2. if local role(process target) is BACKUP, keepalived MASTER side is alive, let keepalived MASTER side do it.
    # workflow:
    # BACKUP deployment is Down.
    # 1) cleanup BACKUP side resources
    # 2) setup a new BACKUP deployment
    # 3) local change the new keepalived config
#    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /root/key root@$monitor_node < "systemctl stop keepalived.service"
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /root/key root@10.79.133.133 < "systemctl stop keepalived.service"
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /root/key root@$remote_ip < /root/stop_2_services

    new_backup_ip=$(getNewDeployment)
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /root/key root@$new_backup_ip < /root/stop_2_services
    python /root/genarate_kp_conf.py --master-ip $monitor_node --backup-ip $new_backup_ip --kp-role MASTER
    # webhook not need to update.
    # python3 cli.py --user <user_name> --password <password> --app <app_name> --ip <webhook_ip> --port <webhook_port>
    python3 cli.py --user moo-ai --password mooopenlab1 --app testopenlabha --ip 111.20.68.219 --port 1236
    systemctl restart keepalived.service
fi


# Here the remote node is not alived.
# We do it locally. This is locally Down, and role is MASTER, so this will setup a whole new AS deployment.
# 1) cleanup remote resources first
# 2) setup a NEW AS deployment
# 3) process external DNS
# 4) delete self
# case local may concurrent MASTER MASTER/ BACKUP , WE ONLY DO THAT IF process_target == local keepallived role
if [ $process_target == $from_kp_role ];then
    # TODO, setup 2 nodes AS deployment
        echo "startup 2 nodes"
fi
