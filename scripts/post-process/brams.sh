#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

INTERFACE_DIR=$(sed -e 's/interface_azure.*$/interface_azure/'<<<$PROGDIR)
source $INTERFACE_DIR/lib/aux_functions.sh


postprocess() {
  local VM_SIZE=$1

  local FILE=$(cat $INTERFACE_DIR/results/brams/$VM_SIZE/*.out)

  is_not_empty $FILE \
    && TIME=$(grep "Time integration ends" <<<$FILE | \
                sed 's/^.*time=//;s/=//g')

  is_not_empty $TIME \
    && echo "$VM_SIZE,$TIME"
}


for experiment in $(ls $INTERFACE_DIR/results/brams)
do
  is_dir $INTERFACE_DIR/results/brams/$experiment \
    && postprocess $experiment
done
