#!/bin/bash

tostatsd() {
    local payload="${1:?Please specify payload}"
    local host="${2:-127.0.0.1}"
    local port="${3:-8125}"

    # Setup UDP socket with statsd server
    exec 3<> "/dev/udp/${host}/${port}"

    # Send data
    printf "%s" "${payload}" >&3

    # Close UDP socket
    exec 3<&-
    exec 3>&-
}

cd "${TINC_CONF_DIR}" || exit 1
mkdir -p "${PROM_STATS_DIR}"
OUTFILE="${PROM_STATS_DIR}/tinc.prom"

while true; do
  echo "" > "${OUTFILE}.$$"
  for nodefile in hosts/*; do
    # Race condition: these files may disappear after entering this loop!
    # We mitigate by testing if we were able to parse the node out.
    node=$(awk '/Subnet/ {gsub(/0\/[0-9]+/, "1"); print $3}' "${nodefile}")
    [[ -z "$node" ]] && continue
    prom_node=$(echo "${node}" | tr '.' '_')
    response_time=$(ping -c 1 "${node}" | awk '/time=/ {gsub(/time=/, ""); print $7}')
    if [ "$response_time" != "" ]; then
      UP=1
    else
      UP=0
      response_time="-1"
    fi
    # use sub-shell for redirected output to outfile:
    {
        echo "# HELP tinc_node_${prom_node}_up reachability of ${node} via the network overlay"
        echo "tinc_node_${prom_node}_up{hostname=\"${HOSTNAME}\"} ${UP}"
        echo "# HELP tinc_node_${prom_node}_response_time response time  of ${node} via the network overlay"
        echo "tinc_node_${prom_node}_response_time{hostname=\"${HOSTNAME}\"} ${response_time}"
    } >> "${OUTFILE}.$$"
    tostatsd "tinc.node_response_time:${response_time}|g|#node:${node}" "${STATSD_HOST:-127.0.0.1}" "${STATSD_PORT:-8125}"
  done
  mv "${OUTFILE}.$$" "${OUTFILE}"
  sleep 60
done
