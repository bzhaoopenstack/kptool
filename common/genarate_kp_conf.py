#!/usr/bin/python
import jinja2
import os
import argparse
import re

ROUTE_REGEX = re.compile(r"default\svia\s([\d+\.]+\d)\sdev\s(\w+)\sonlink.*")


def StoreToFile(req_dict):
    template_loader = jinja2.FileSystemLoader(
        searchpath=os.path.dirname("/root/kp.template"))
    JINJA_ENV = jinja2.Environment(autoescape=True,
                                   loader=template_loader,
                                   trim_blocks=True,
                                   lstrip_blocks=True)
    f_str = JINJA_ENV.get_template(
        os.path.basename(os.path.basename("/root/kp.template"))).render(
        req_dict)
    with open("/root/ff", "w") as f:
       f.write(f_str)


def getLocalInterface():
    exec_cmd = os.popen("ip route")
    res = exec_cmd.readlines()
    for line in res:
        if "default via" in line:
            get_res = ROUTE_REGEX.findall(line)
            break
    return get_res[0][0], get_res[0][1]


def prepareDict(args):
    _, local_interface = getLocalInterface()
    return {
        'keepalived_role': args.kp_role,
        'local_interface': local_interface,
        'vip': '10.0.0.188',
        'master_ip': args.master_ip,
        'backup_ip': args.backup_ip
    }


def main(args):
    req = prepareDict(args)
    StoreToFile(req)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Keepalived conf file regenarate tools',
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('--kp-role',  metavar='<kp_role>', required=True,
                        help="Keepalived Role, MASTER/BACKUP")
    parser.add_argument('--master-ip', metavar='<master_ip>', required=True,
                        help="The IP of Master Depolyment")
    parser.add_argument('--backup-ip', metavar='<backup_ip>', required=True,
                        help="The IP of Backup Depolyment")
    parser.add_argument('--vip', metavar='<vip>', required=False,
                        help="The VIP, must be exist on local host")
    parser.add_argument('--interface', metavar='<interface>', required=False,
                        help="The track Interface on local host")
    args = parser.parse_args()
    main(args)
