#!/bin/bash


readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"


source lib/azure_functions.sh
source lib/aux_functions.sh


main() {
  cmdline $ARGS

  is_empty $CONFIG_FILE \
    && die 'ERROR: run.sh needs a configure file. Try $ run.sh -h.'

  is_empty $LOCATION \
    && LOCATION="$(get_location $CONFIG_FILE)"

  is_empty $SUBSCRIPTION \
    && SUBSCRIPTION="$(get_subscription $CONFIG_FILE)"

  local BENCHMARK="$(get_benchmark $CONFIG_FILE)"

  local CONFIGURE_CORES=$(get_cores $CONFIG_FILE)
  local CONFIGURE_INSTANCES=$(get_instances $CONFIG_FILE)

  local ADMINPASSWORD=$(get_adminpassword $CONFIG_FILE)
  local PASSMOUNT=$(get_passmount $CONFIG_FILE)
  local DISKURL=$(get_diskurl $CONFIG_FILE)
  local DISKUSERNAME=$(get_diskusername $CONFIG_FILE)

  local TEMPLATE_FILE=$(get_templatefile $CONFIG_FILE)
  local IMAGE=$(get_image $CONFIG_FILE)

  local FILE_SHARED_PARAMETERS="${ADMINPASSWORD} ${PASSMOUNT} ${DISKURL} ${DISKUSERNAME}"


  az account set -s "$SUBSCRIPTION"

  # VM_SIZE=$(get_vmsize $CONFIG_FILE)
  # VM_CORES=$(get_cores $CONFIG_FILE)
  # number_instances=$(get_instances $CONFIG_FILE)
  # mkdir -p complete_logs
  #
  # # echo "$VM_SIZE $VM_CORES $NUMBER_INSTANCES"
  # echo "$VM_SIZE $VM_CORES $number_instances $LOCATION $TEMPLATE_FILE"
  # ./lib/main.sh $BENCHMARK \
  #   ${FILE_SHARED_PARAMETERS} \
  #   ${number_instances} \
  #   ${VM_SIZE} \
  #   ${VM_CORES} \
  #   ${TEMPLATE_FILE} \
  #   ${IMAGE} \
  #   ${LOCATION} 2>&1 | tee -a complete_logs/${VM_SIZE}_${number_instances}.log
  # sleep 5

  local MODE=$(get_mode $CONFIG_FILE)


  for cores in $CONFIGURE_CORES
  do
  	for number_instances in $CONFIGURE_INSTANCES
  	do
  		for instance in $(cat machines/vm_sizes_${LOCATION}_$cores)
  		do

  			VM_SIZE=$(sed 's/,.*//' <<<$instance )
  			VM_CORES=$(sed 's/[^,]*,\([^,]*\).*/\1/' <<<$instance )

        # character '#' means that VM_SIZE is commented
  			if [ ! -z $(grep "#" <<< "$instance") ]
  			then
          echo "$VM_SIZE comentada"
  			else
          if [ "$MODE" = "parallel" ]
          then
            echo -e "$number_instances\t$VM_CORES\t$VM_SIZE"
            ./main.sh $BENCHMARK \
                      ${FILE_SHARED_PARAMETERS} \
                      ${number_instances} \
                      ${VM_SIZE} \
                      ${VM_CORES} \
                      ${TEMPLATE_FILE} \
                      ${LOCATION} 2>&1 | \
                      tee -a complete_${VM_SIZE}_${number_instances}.log &
            sleep 5
          else
            echo -e "$number_instances\t$VM_CORES\t$VM_SIZE"
            ./main.sh $BENCHMARK \
                      ${FILE_SHARED_PARAMETERS} \
                      ${number_instances} \
                      ${VM_SIZE} \
                      ${VM_CORES} \
                      ${TEMPLATE_FILE} \
                      ${LOCATION} 2>&1 | \
                      tee -a complete_${VM_SIZE}_${number_instances}.log
            sleep 5
          fi
  			fi
  		done
      wait
      echo "****************************************"
  	done
  done




}
main
