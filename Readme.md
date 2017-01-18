Docker container to export tinc overlay network conectivity as prometueus stats via the node exporter text format.
Requires to environment variables to be set:

TINC_CONF_DIR: directory to read the tinc configuration from
PROM_STATS_DIR: directory to write the prometheus stats to.

this tinc conf dir and the promehteus stats dir should be mounted via bind mounts.
