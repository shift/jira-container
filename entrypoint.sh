#!/bin/sh
set
set -e

: ${CLUSTERPATH:=jira}
: ${KV_IP:=127.0.0.1}
: ${KV_PORT:=4001}

if [ ! -z "${KV_CA_CERT}" ]; then
    KV_TLS="--ca-cert=${KV_CA_CERT} --client-cert=${KV_CLIENT_CERT} --client-key=${KV_CLIENT_KEY}"
    CONFD_KV_TLS="-scheme=https -client-ca-keys=${KV_CA_CERT} -client-cert=${KV_CLIENT_CERT} -client-key=${KV_CLIENT_KEY}"
fi

# log with timestamp
log() {
  if [ -z "$*" ]; then
    return 1
  fi

  TIMESTAMP=$(date '+%F %T')
  echo "${TIMESTAMP}  $0: $*"
  return 0
}

# make sure etcd uses http or https as a prefix
if [[ "$KV_TYPE" == "etcd" ]]; then
    if [ ! -z "${KV_CA_CERT}" ]; then
          CONFD_NODE_SCHEMA="https://"
    else
          CONFD_NODE_SCHEMA="http://"
    fi
fi


kviator --kvstore=${KV_TYPE} --client=${KV_IP}:${KV_PORT} ${KV_TLS} put ${CLUSTER_PATH}/Xms 2GB
kviator --kvstore=${KV_TYPE} --client=${KV_IP}:${KV_PORT} ${KV_TLS} put ${CLUSTER_PATH}/Xmx 2GB

# kviator --kvstore=${KV_TYPE} --client=${KV_IP}:${KV_PORT} ${KV_TLS} put ${CLUSTER_PATH}/monKeyring - < /etc/ceph/${CLUSTER}.mon.keyring

until confd -onetime -backend ${KV_TYPE} -node ${CONFD_NODE_SCHEMA}${KV_IP}:${KV_PORT} ${CONFD_KV_TLS} -prefix="/${CLUSTER_PATH}/" ; do
  log "Waiting for confd to update templates..."
  sleep 1
done
