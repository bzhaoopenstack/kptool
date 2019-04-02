
import requests
import json

# Simpledns provider
base_api_url = 'https://api.dnsimple.com/v2/'
DOMAIN_NAME = 'status.openlabtesting.org'
#ACCOUNT_ID = {{ dns_account_id }}
#TARGET_ORI_IP = {{ dns_old_ip }}
#TARGET_CHANGE_IP = {{ dns_new_ip }}
TARGET_ORI_IP = '1.1.1.1'
TARGET_CHANGE_IP = '2.2.2.2'
TOKEN = '5Ki5xbVwGQe9QxMdTcejLw4GcjIIlmkA'
GLOBAL_SESSION = requests.session()


def main():
    headers = {'Authorization': "Bearer %s" % TOKEN,
               'Accept': 'application/json'}
    res = requests.get(base_api_url + 'accounts', headers=headers)
    if res.status_code != 200:
        print("Failed to get the accounts")
        print("Details: code-status %s\n         message: %s" % (
            res.status_code, res.reason))
        exit(1)
    accounts = json.loads(s=res.content)['data']
    account_id = None
    for account in accounts:
        if 'zhaobo6' in account['email']:
            account_id = account['id']
            break
    if not account_id:
        print("Failed to get the account_id")
        exit(1)

    res = requests.get(base_api_url + "%s/zones/%s/records?name=%s" % (
        account_id, DOMAIN_NAME, DOMAIN_NAME), headers=headers)
    if res.status_code != 200:
        print("Failed to get the records by name")
        print("Details: code-status %s\n         message: %s" % (
            res.status_code, res.reason))
        exit(1)
    records = json.loads(s=res.content)['data']
    record_id = None
    for record in records:
        if TARGET_ORI_IP in record['content']:
            record_id = record['id']
            break
    if record_id:
        print("Failed to get the record_id")
        exit(1)

    headers['Content-Type'] = 'application/json'
    data = {
        "content": TARGET_CHANGE_IP,
        "ttl": 3600,
        "priority": 20,
        "regions": ["global"]
    }
    res = requests.patch(base_api_url + "%s/zones/%s/records/%s" % (
        account_id, DOMAIN_NAME, record_id), data=data,
                         headers=headers)
    result = json.loads(s=res.content)['data']
    if res.status_code == 200 and result['content'] == TARGET_CHANGE_IP:
        print("Success Update")
    else:
        print("Fail Update")
        print("Details: code-status %s\n         message: %s" % (
            res.status_code, res.reason))
        exit(1)


if __name__ == "__main__":
    main()
