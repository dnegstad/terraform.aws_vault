#!/bin/bash
set -e

METADATA_INSTANCE_ID=`curl http://169.254.169.254/2014-02-25/meta-data/instance-id`
LOCAL_IPV4=`curl http://169.254.169.254/2014-02-25/meta-data/local-ipv4`

# Report that Consul is ready to use. Consul's KV store is used in
# Vault setup and other places, set a ready value in its KV store
# to signify that it is ready.
SLEEPTIME=1
cget_leaders() { curl -sf "http://127.0.0.1:8500/v1/status/leader"; }

# Wait for the Consul cluster to become ready
while cget_leader | grep "^\"\"$"; do
  if [ $SLEEPTIME -ge 24 ]; then
    echo "ERROR: CONSUL DID NOT COMPLETE SETUP! Manual intervention required on node $METADATA_INSTANCE_ID)}."
    exit 2
  else
    echo "Blocking until Consul is ready, waiting $SLEEPTIME second(s)..."
    sleep $SLEEPTIME
    ((SLEEPTIME+=1))
  fi
done

echo "Consul is ready!"
