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
