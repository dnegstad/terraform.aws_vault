#!/bin/bash

METADATA_INSTANCE_ID=`curl http://169.254.169.254/2014-02-25/meta-data/instance-id`

sudo cat <<EOF >/etc/consul.d/service.json
{
  "service": {
    "id": "${name}-${METADATA_INSTANCE_ID}",
    "name": "vault",
    "port": 8200,
    "tags": [
      "server"
    ],
    "check": {
      "id": "vault",
      "name": "Vault Health Status",
      "http": "http://localhost:8200/v1/sys/health",
      "interval": "10s",
      "timeout": "1s"
    }
  }
}
EOF
