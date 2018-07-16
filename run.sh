#!/bin/bash


readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

INTERFACE_DIR=$(sed -e 's/interface_azure.*$/interface_azure/'<<<$PROGDIR)

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

  local ADMIN_PASSWORD=$(get_adminpassword $CONFIG_FILE)
  local ADMIN_USERNAME=$(get_adminusername $CONFIG_FILE)

  local PASSMOUNT=$(get_passmount $CONFIG_FILE)
  local DISKURL=$(get_diskurl $CONFIG_FILE)
  local DISKUSERNAME=$(get_diskusername $CONFIG_FILE)

  local TEMPLATE_FILE=$(get_templatefile $CONFIG_FILE)
  local IMAGE=$(get_image $CONFIG_FILE)

  local FILE_SHARED_PARAMETERS="${PASSMOUNT} ${DISKURL} ${DISKUSERNAME}"

  local MODE=$(get_mode $CONFIG_FILE)
  local ROLE=$(get_role $CONFIG_FILE)


  az account set -s "$SUBSCRIPTION"
  echo $PROGDIR


if [ "$ROLE" = "single" ]
then
  VM_SIZE=$(get_vmsize $CONFIG_FILE)
  VM_CORES=$(get_cores $CONFIG_FILE)
  number_instances=$(get_instances $CONFIG_FILE)
  mkdir -p complete_logs

  # echo "$VM_SIZE $VM_CORES $NUMBER_INSTANCES"
  echo "$VM_SIZE $VM_CORES $number_instances $LOCATION $TEMPLATE_FILE"
  ./lib/main.sh $BENCHMARK \
    ${ADMIN_USERNAME} \
    ${ADMIN_PASSWORD} \
    ${FILE_SHARED_PARAMETERS} \
    ${number_instances} \
    ${VM_SIZE} \
    ${VM_CORES} \
    ${TEMPLATE_FILE} \
    ${IMAGE} \
    ${LOCATION} 2>&1 | tee -a complete_logs/${VM_SIZE}_${number_instances}.log
  sleep 5

elif [ "$ROLE" = "multiple" ]
then
  for cores in $CONFIGURE_CORES
  do
    for number_instances in $CONFIGURE_INSTANCES
    do
      for instance in $(cat machines/vm_sizes_${LOCATION}_$cores)
      do

        VM_SIZE=$(sed 's/,.*//' <<<$instance )
        VM_CORES=$(sed 's/[^,]*,\([^,]*\).*/\1/' <<<$instance )

        VM_SIZE_FORMATTED=$(remove_special_characters $VM_SIZE )
        VM_SIZE_FORMATTED=$(to_lower_case $VM_SIZE_FORMATTED )

        # echo "$VM_SIZE $VM_CORES $NUMBER_INSTANCES"

        # character '#' means thtatz
        if [ ! -z $(grep "#" <<< "$instance") ]
        then
          echo "$VM_SIZE comentada"
        else
          EXECUTA="0"
          # se diretorio existe
          if [ -d "$INTERFACE_DIR/results/brams/${VM_SIZE}_${number_instances}" ]
          then
            DIRFILE=$INTERFACE_DIR/results/brams/${VM_SIZE}_${number_instances}/log_meteo_only_${VM_SIZE_FORMATTED}.out

            if [ ! -f "$FILE" ]
            then
              # arquivo nao existe
              EXECUTA="1"
            else
              TIME=$(grep "Time integration ends" $FILE | \
                sed 's/^.*time=//;s/=//g;s/..$//')

              if [ -z "$TIME" ]
              then
                # nao tem tempo calculado
                EXECUTA="1"
              fi
            fi
          else
            # diretorio nao existe
            EXECUTA="1"
          fi

            # DIRFILES="$(ls $INTERFACE_DIR/results/brams/${VM_SIZE}_${NUMBER_INSTANCES}/)"
            # se o arquivo nao existe
          #   if [ ! -z "$DIRFILES" ]
          #   then
          #     EXECUTA="1"
          #   fi
          # else
          #   EXECUTA="1"
          # fi

          if [ "$EXECUTA" = "1" ]
          then
            if [ "$MODE" = "parallel" ]
            then
              echo "$VM_SIZE $VM_CORES $number_instances running parallel"
              ./lib/main.sh $BENCHMARK \
                ${ADMIN_USERNAME} \
                ${ADMIN_PASSWORD} \
                ${FILE_SHARED_PARAMETERS} \
                ${number_instances} \
                ${VM_SIZE} \
                ${VM_CORES} \
                ${TEMPLATE_FILE} \
                ${IMAGE} \
                ${LOCATION} 2>&1 | \
                tee -a complete_logs/${VM_SIZE}_${number_instances}.log &
              sleep 5
            elif [ "$MODE" = "sequencial" ]
            then
              echo "$VM_SIZE $VM_CORES $number_instances running sequencial"
              ./lib/main.sh $BENCHMARK \
                ${ADMIN_USERNAME} \
                ${ADMIN_PASSWORD} \
                ${FILE_SHARED_PARAMETERS} \
                ${number_instances} \
                ${VM_SIZE} \
                ${VM_CORES} \
                ${TEMPLATE_FILE} \
                ${IMAGE} \
                ${LOCATION} 2>&1 | \
                tee -a complete_logs/${VM_SIZE}_${number_instances}.log
              sleep 5
            else
              die "ERROR: variable MODE in $CONFIG_FILE must be parallel or sequencial, got MODE=$MODE"
            fi
          else
            echo "Experiment with $NUMBER_INSTANCES instances of $VM_SIZE ($VM_CORES cores) already exists. Didn't deploy."
          fi

        fi
        EXECUTA="0"
      done
      wait
    done
  done
else
  die "ERROR: variable ROLE in $CONFIG_FILE must be single or multiple, got ROLE=$ROLE"
fi

}
main
