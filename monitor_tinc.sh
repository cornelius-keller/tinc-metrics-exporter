#!/bin/bash
cd $TINC_CONF_DIR
mkdir -p $PROM_STATS_DIR
OUTFILE="$PROM_STATS_DIR/tinc.prom"

while true; do
  echo "" > $OUTFILE.$$
  for nodefile in $(ls hosts/core*); do
    node=$( cat $nodefile | grep Subnet | sed -e 's/Subnet = //' | sed -e 's/0\/24/1/')
    response_time=$(ping -c 1 $node |grep time= | awk '{ print $7}' | sed -e  's/time=//')
     if [ $? -eq 0 ]; then
       echo "# HELP tinc_node_$( echo $node | sed -e 's/\./_/g')_up reachability of $node via the network overlay" >> $OUTFILE.$$
       echo  tinc_node_$( echo $node | sed -e 's/\./_/g')_up{hostname=\"$HOSTNAME\"}: 1 >> $OUTFILE.$$
       echo "# HELP tinc_node_$( echo $node | sed -e 's/\./_/g')_response_time response time  of $node via the network overlay" >> $OUTFILE.$$
          readOnly: false
       echo tinc_node_$( echo $node | sed -e 's/\./_/g')_response_time{hostname=\"$HOSTNAME\"}: $response_time >> $OUTFILE.$$
     else
       echo "# HELP tinc_node_$( echo $node | sed -e 's/\./_/g')_up reachability of $node via the network overlay" >> $OUTFILE.$$
       echo tinc_node_$( echo $node | sed -e 's/\./_/g')_up{hostname=\"$HOSTNAME\"}: 0 >> $OUTFILE.$$
       echo "# HELP tinc_node_$( echo $node | sed -e 's/\./_/')_response_time response time  of $node via the network overlay" >> $OUTFILE.$$
       echo tinc_node_$( echo $node | sed -e 's/\./_/g')_response_time{hostname=\"$HOSTNAME\"}: -1 >> $OUTFILE.$$
     fi
  done

  cp $OUTFILE.$$ $OUTFILE
  rm $OUTFILE.$$
  sleep 60
done
