#!/bin/bash

METADATA_INSTANCE_ID=`curl http://169.254.169.254/2014-02-25/meta-data/instance-id`

cat <<EOF >/tmp/vault_service.json
{
  "service": {
    "id": "{{ id }}",
    "name": "vault",
    "port": 8200,
    "tags": [
      "server"
    ],
    "check": {
      "id": "vault",
      "name": "Vault Health Status",
      "http": "https://127.0.0.1:8200/v1/sys/health",
      "interval": "10s",
      "timeout": "1s"
    }
  }
}
EOF

sudo mv /tmp/vault_service.json /opt/consul/conf/vault_service.json
sudo chown root:root /opt/consul/conf/vault_service.json
sudo chmod 640 /opt/consul/conf/vault_service.json

sudo sed -i -- "s/{{ id }}/${name}-$METADATA_INSTANCE_ID/g" /opt/consul/conf/vault_service.json

echo "Vault Service registered"
