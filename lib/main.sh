#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

source lib/azure_functions.sh
source lib/aux_functions.sh
source lib/bench/brams.sh


main() {

  # *******************************************************************
  # CONFIGURE ENVIROMENT
  # *******************************************************************

  set -x

  local BENCHMARK=${1}
  # read arguments
  # mountpoint parameters
  local ADMINPASSWORD=${2}
  local PASSMOUNT=${3}
  local DISKURL=${4}
  local DISKUSERNAME=${5}

  # azure number of machines
  local NUMBER_INSTANCES=${6}
  local VM_SIZE=${7}
  local NUMBER_PROCESSORS=${8}

  local TEMPLATE_FILE=${9}
  local IMAGE=${10}
  local LOCATION=${11}

  local RESOURCE_GROUP=legion${RANDOM}

  local VM_SIZE_FORMATTED=$(remove_special_characters $VM_SIZE )
  VM_SIZE_FORMATTED=$(to_lower_case $VM_SIZE_FORMATTED )
  # VM_SIZE_FORMATTED is something like: standarda3v2


  # variables to use with a FILESHARE system. If you are running SPITZ
  # $ QUOTA (in Gib) is the size of your fileshare system
  # $ FILESHARE is the name of yout fileshare system which each vm is going to mount
  local QUOTA=15
  # manipulate file share name --> remove special characters, and to lowerCaseFy
  local FILESHARE="${BENCHMARK}${NUMBER_INSTANCES}x${VM_SIZE}"
  FILESHARE=$(remove_special_characters $FILESHARE)
  FILESHARE=$(to_lower_case $FILESHARE)
  # FILESHARE is something like : brams4xstandarda3v2


  # folders to throw outputs
  LOG_DIR="log/$BENCHMARK/${VM_SIZE}_${NUMBER_INSTANCES}"
  RESULTS_DIR="results/$BENCHMARK/${VM_SIZE}_${NUMBER_INSTANCES}"

  # create folders
  mkdir -p log
  mkdir -p results
  mkdir -p log/$BENCHMARK
  mkdir -p results/$BENCHMARK

  mkdir -p $RESULTS_DIR

  LOG_FILE="${LOG_DIR}/${VM_SIZE}_${NUMBER_INSTANCES}.log"


# *******************************************************************
# START - CONFIGURE INFRASTRUCTURE
# *******************************************************************
  init_log

  create_group $RESOURCE_GROUP $LOCATION


  # discomment if your application needs a fileshare system, like SPITZ
  create_fileshare $FILESHARE \
                    $PASSMOUNT \
                    $DISKUSERNAME \
                    $QUOTA

  # If your application needs a fileshare system, add $FILESHARE as the last parameter in create_machines
  create_machines $RESOURCE_GROUP \
                  $TEMPLATE_FILE \
                  $VM_SIZE \
                  $ADMINPASSWORD \
                  $PASSMOUNT \
                  $DISKURL \
                  $DISKUSERNAME \
                  $NUMBER_INSTANCES \
                  $IMAGE # $FILESHARE (optional)

  local SSH_ADDR=$(setup_ssh_keys $RESOURCE_GROUP)

  # discomment if application needs hostfile, like if you are running MPI
  local PATH_TO_HOSTFILE=$(generate_hostfile $NUMBER_INSTANCES)

# *******************************************************************
# BENCHMARK --
# *******************************************************************

  #
  local BRAMSDIR="/home/username/BRAMS"
  local BRAMSDIRBIN="/home/username/bin"
  local SAMPLEDIR="/home/username/meteo-only"

  run_brams $SSH_ADDR \
            $BRAMSDIR \
            $BRAMSDIRBIN \
            $SAMPLEDIR \
            $NUMBER_INSTANCES \
            $VM_SIZE_FORMATTED \
            $(($NUMBER_PROCESSORS * $NUMBER_INSTANCES))


}

main $ARGS
