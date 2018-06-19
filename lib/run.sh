#!/bin/bash


readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"


source azure_functions.sh
source aux_functions.sh



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

  local FILE_SHARED_PARAMETERS="${ADMINPASSWORD} ${PASSMOUNT} ${DISKURL} ${DISKUSERNAME}"


  az account set -s "$SUBSCRIPTION"

  VM_SIZE=$(get_vmsize $CONFIG_FILE)
  VM_CORES=$(get_cores $CONFIG_FILE)
  number_instances=$(get_instances $CONFIG_FILE)
  # echo "$VM_SIZE $VM_CORES $NUMBER_INSTANCES"
  echo "$VM_SIZE $VM_CORES $number_instances $LOCATION $TEMPLATE_FILE"
  ./main.sh $BENCHMARK \
    ${FILE_SHARED_PARAMETERS} \
    ${number_instances} \
    ${VM_SIZE} \
    ${VM_CORES} \
    ${TEMPLATE_FILE} \
    ${LOCATION} 2>&1 | tee -a complete_${VM_SIZE}_${number_instances}.log
  sleep 5


  # for cores in $CONFIGURE_CORES
  # do
  # 	for number_instances in $CONFIGURE_INSTANCES
  # 	do
  # 		for instance in $(cat ../machines/vm_sizes_${LOCATION}_$cores)
  # 		do
  # 			VM_SIZE=$(sed 's/,.*//' <<<$instance )
  # 			VM_CORES=$(sed 's/[^,]*,\([^,]*\).*/\1/' <<<$instance )
  # 			# echo "$VM_SIZE $VM_CORES $NUMBER_INSTANCES"
  #
  # 			if [ -z $VM_SIZE ]
  # 			then
  #         echo "NAO TEM NADA"
  # 			else
  #         echo "$VM_SIZE $VM_CORES $number_instances $LOCATION"
  #         ./main.sh $BENCHMARK \
  #                   ${FILE_SHARED_PARAMETERS} \
  #                   ${number_instances} \
  #                   ${VM_SIZE} \
  #                   ${VM_CORES} \
  #                   ${TEMPLATE_FILE} \
  #                   ${LOCATION} 2>&1 | tee -a complete_${VM_SIZE}_${number_instances}.log &
  #         # sleep 5
  # 			fi
  # 		done
  #     wait
  # 	done
  # done




}
main
