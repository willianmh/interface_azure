#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

INTERFACE_DIR=$(sed -e 's/interface_azure.*$/interface_azure/'<<<$PROGDIR)
source $INTERFACE_DIR/lib/aux_functions.sh

# set -x

postprocess() {
  local VM_SIZE=$1
  local NUMBER_INSTANCES=$2

  local VM_SIZE_FORMATTED=$(remove_special_characters $VM_SIZE )
  VM_SIZE_FORMATTED=$(to_lower_case $VM_SIZE_FORMATTED )

  local FILE=$INTERFACE_DIR/results/brams/${VM_SIZE}_${NUMBER_INSTANCES}/log_meteo_only_${VM_SIZE_FORMATTED}.out

  if [ ! -f "$FILE" ]
  then
    echo "0.00" | tr '\n' ',' >> time_brams.out
  else
    local TIME=$(grep "Time integration ends" $FILE | \
      sed 's/^.*time=//;s/=//g;s/..$//')

    is_not_empty $TIME \
      && echo "$TIME" | tr '\n' ',' >> time_brams.out

    is_empty $TIME \
      && echo "0.00" | tr '\n' ',' >> time_brams.out
  fi

  # local DIR="$(ls $INTERFACE_DIR/results/brams/${VM_SIZE}_${NUMBER_INSTANCES}/)"
  # if [ -z $DIR ]
  # then
  #   echo "0.00" | tr '\n' ',' >> time_brams.out
  # else
  #   local TIME=$(grep "Time integration ends" $FILE | \
  #     sed 's/^.*time=//;s/=//g;s/..$//')
  #
  #   is_not_empty $TIME \
  #     && echo "$TIME" | tr '\n' ',' >> time_brams.out
  #
  #   is_empty $TIME \
  #     && echo "0.00" | tr '\n' ',' >> time_brams.out
  # fi

}

cmdline $ARGS


is_empty $CONFIG_FILE \
  && die 'ERROR: run.sh needs a configure file. Try $ run.sh -h.'

is_empty $LOCATION \
  && LOCATION="$(get_location $CONFIG_FILE)"

echo "BRAMS execution model" > time_brams.out


CONFIGURE_CORES=$(get_cores $CONFIG_FILE)
CONFIGURE_INSTANCES=$(get_instances $CONFIG_FILE)

sleep 1

for cores in $CONFIGURE_CORES
do

  echo "$cores cores" >> time_brams.out

  for instance in $(cat $INTERFACE_DIR/machines/vm_sizes_${LOCATION}_$cores)
  do


    if [ ! -z $(grep "#" <<< "$instance") ]
    then
      instance=$(sed 's/#//g' <<< $instance)
    fi

    VM_SIZE=$(sed 's/,.*//' <<<$instance )

    echo "$VM_SIZE" | tr '\n' ',' >> time_brams.out

    for number_instances in $CONFIGURE_INSTANCES
    do
      # echo "$instance $number_instances"
      # set -x

      is_dir $INTERFACE_DIR/results/brams/${VM_SIZE}_${number_instances} \
        && postprocess ${VM_SIZE} ${number_instances}

      is_not_dir $INTERFACE_DIR/results/brams/${VM_SIZE}_${number_instances} \
        && echo "0.00" | tr '\n' ',' >> time_brams.out
      # set +x
    done
    echo "" >> time_brams.out

  done
done
sed 's/\,[^\,]*$//' time_brams.out > time_brams.csv
sed 's/,/\t/g' time_brams.csv > time_brams.tsv

rm time_brams.out
