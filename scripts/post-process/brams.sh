#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

INTERFACE_DIR=$(sed -e 's/interface_azure.*$/interface_azure/'<<<$PROGDIR)
source $INTERFACE_DIR/lib/aux_functions.sh


postprocess() {
  local VM_SIZE=$1

  local TIME=$(cat $INTERFACE_DIR/results/brams/$VM_SIZE/*.out | \
      grep "Time integration ends" | \
      sed 's/^.*time=//;s/=//g')

  is_not_empty $TIME \
    && echo "$VM_SIZE,$TIME" >> time_brams.out
}

echo "BRAMS execution model" > time_brams.out



for experiment in $(ls $INTERFACE_DIR/results/brams)
do
  is_dir $INTERFACE_DIR/results/brams/$experiment \
    && postprocess $experiment
done


local CONFIGURE_CORES=$(get_cores $CONFIG_FILE)
local CONFIGURE_INSTANCES=$(get_instances $CONFIG_FILE)

for cores in $CONFIGURE_CORES
do

  echo "$cores cores" >> time_brams.out

    for instance in in $(cat $INTERFACE_DIR/machines/vm_sizes_${LOCATION}_$cores)
    do
      for number_instances in $CONFIGURE_INSTANCES
      do

      local VM_SIZE=$(sed 's/,.*//' <<<$instance )

      if [ ! -z $(grep "#" <<< "$instance") ]
      then
        echo "$VM_SIZE commented"
      else
      is_dir $INTERFACE_DIR/results/brams/${VM_SIZE}_${number_instances} \
        && postprocess ${VM_SIZE} ${number_instances}
      fi
    done
  done
done
